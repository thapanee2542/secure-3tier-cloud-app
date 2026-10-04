import json
import os
from pathlib import Path
import runpy
import sys
import unittest
from decimal import Decimal
from types import ModuleType
from unittest.mock import MagicMock, call, patch


HANDLER_PATH = Path(__file__).resolve().parents[1] / "get_members.py"


class GetMembersTests(unittest.TestCase):
    def setUp(self):
        self.table = MagicMock()
        boto3_mock = ModuleType("boto3")
        resource_mock = MagicMock()
        resource_mock.return_value.Table.return_value = self.table
        boto3_mock.resource = resource_mock

        environment_patch = patch.dict(os.environ, {
            "TABLE_NAME": "test-members",
            "IMAGE_BASE_URL": "https://example.com/",
        })
        environment_patch.start()
        self.addCleanup(environment_patch.stop)

        with patch.dict(sys.modules, {"boto3": boto3_mock}):
            self.module = runpy.run_path(str(HANDLER_PATH))

        resource_mock.assert_called_once_with("dynamodb")
        resource_mock.return_value.Table.assert_called_once_with("test-members")
        self.handler = self.module["lambda_handler"]

        logger_patch = patch.object(self.module["logger"], "exception")
        self.exception_logger = logger_patch.start()
        self.addCleanup(logger_patch.stop)

    def assert_response(self, response, status_code, body):
        self.assertEqual(response, {
            "statusCode": status_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(body),
        })

    def assert_error_response(self, response):
        self.assert_response(response, 500, {"message": "Internal server error"})
        self.exception_logger.assert_called_once()

    def test_returns_members_with_image_urls(self):
        self.table.scan.return_value = {
            "Items": [{"memberId": "1", "studentId": "101", "name": "Alice"}],
        }

        response = self.handler({}, None)

        self.assert_response(response, 200, [{
            "memberId": "1",
            "studentId": "101",
            "name": "Alice",
            "imagePath": "https://example.com/images/101.jpg",
        }])
        self.table.scan.assert_called_once_with()

    def test_collects_all_scan_pages(self):
        cursor = {"memberId": "1"}
        self.table.scan.side_effect = [
            {"Items": [{"studentId": "101"}], "LastEvaluatedKey": cursor},
            {"Items": [{"studentId": "102"}]},
        ]

        response = self.handler({}, None)

        self.assert_response(response, 200, [
            {"studentId": "101", "imagePath": "https://example.com/images/101.jpg"},
            {"studentId": "102", "imagePath": "https://example.com/images/102.jpg"},
        ])
        self.assertEqual(self.table.scan.call_args_list, [
            call(),
            call(ExclusiveStartKey=cursor),
        ])

    def test_continues_after_empty_page_with_cursor(self):
        cursor = {"memberId": "1"}
        self.table.scan.side_effect = [
            {"Items": [], "LastEvaluatedKey": cursor},
            {"Items": [{"studentId": "102"}]},
        ]

        response = self.handler({}, None)

        self.assert_response(response, 200, [{
            "studentId": "102",
            "imagePath": "https://example.com/images/102.jpg",
        }])
        self.assertEqual(self.table.scan.call_args_list, [
            call(),
            call(ExclusiveStartKey=cursor),
        ])

    def test_returns_empty_array_when_table_has_no_members(self):
        for page in ({}, {"Items": []}):
            with self.subTest(page=page):
                self.table.scan.return_value = page
                self.assert_response(self.handler({}, None), 200, [])

    def test_empty_table_does_not_require_image_base_url(self):
        self.table.scan.return_value = {"Items": []}
        del os.environ["IMAGE_BASE_URL"]

        self.assert_response(self.handler({}, None), 200, [])

    def test_converts_decimal_values_to_json_numbers(self):
        self.table.scan.return_value = {"Items": [{
            "studentId": "101",
            "integer": Decimal("2"),
            "fraction": Decimal("2.5"),
        }]}

        self.assert_response(self.handler({}, None), 200, [{
            "studentId": "101",
            "integer": 2,
            "fraction": 2.5,
            "imagePath": "https://example.com/images/101.jpg",
        }])

    def test_returns_generic_error_when_scan_fails(self):
        self.table.scan.side_effect = RuntimeError("Private database details")

        self.assert_error_response(self.handler({}, None))

    def test_returns_generic_error_when_later_scan_page_fails(self):
        self.table.scan.side_effect = [
            {"Items": [{"studentId": "101"}], "LastEvaluatedKey": {"memberId": "1"}},
            RuntimeError("Private database details"),
        ]

        self.assert_error_response(self.handler({}, None))

    def test_returns_generic_error_when_student_id_is_missing(self):
        self.table.scan.return_value = {"Items": [{"memberId": "1"}]}

        self.assert_error_response(self.handler({}, None))

    def test_returns_generic_error_when_image_base_url_is_missing(self):
        self.table.scan.return_value = {"Items": [{"studentId": "101"}]}
        del os.environ["IMAGE_BASE_URL"]

        self.assert_error_response(self.handler({}, None))

    def test_returns_generic_error_for_unsupported_json_value(self):
        self.table.scan.return_value = {
            "Items": [{"studentId": "101", "unsupported": {1, 2}}],
        }

        self.assert_error_response(self.handler({}, None))


if __name__ == "__main__":
    unittest.main()