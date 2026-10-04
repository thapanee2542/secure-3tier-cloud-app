import React from 'react';
import { Document as PdfDocument, Page as PdfPage, pdfjs } from 'react-pdf';
import { ChevronLeft, ChevronRight, ExternalLink, FileText, X } from 'lucide-react';

pdfjs.GlobalWorkerOptions.workerSrc = new URL('pdfjs-dist/build/pdf.worker.min.mjs', import.meta.url).toString();

export function PdfPagePreview({ file }) {
  const [pageCount, setPageCount] = React.useState(0);
  const [hasError, setHasError] = React.useState(false);

  return (
    <div className="feature-pdf-preview">
      <div className="feature-pdf-toolbar">
        <span><FileText size={15} /> PDF</span>
        <span aria-live="polite">{pageCount ? `${pageCount} หน้า` : ''}</span>
      </div>
      <div className="feature-pdf-stage">
        {hasError ? (
          <p role="alert">โหลดตัวอย่าง PDF ไม่สำเร็จ</p>
        ) : (
          <PdfDocument
            file={file}
            loading={<p>กำลังโหลดตัวอย่าง PDF…</p>}
            error={<p role="alert">โหลดตัวอย่าง PDF ไม่สำเร็จ</p>}
            onLoadSuccess={({ numPages }) => setPageCount(numPages)}
            onLoadError={() => setHasError(true)}
            onSourceError={() => setHasError(true)}
          >
            <PdfPage
              pageNumber={1}
              width={640}
              renderTextLayer={false}
              renderAnnotationLayer={false}
              loading={<p>กำลังแสดงหน้าแรก…</p>}
            />
          </PdfDocument>
        )}
      </div>
    </div>
  );
}

function PdfViewer({ pdfDocument, pageNumber, pageCount, hasError, onPageChange, onPageCountChange, onError, onClose }) {
  return (
    <dialog open className="pdf-viewer" aria-modal="true" aria-label={`เอกสาร ${pdfDocument.title}`}>
      <div className="pdf-toolbar">
        <div className="pdf-title"><span className="document-number">{pdfDocument.number}</span><span>{pdfDocument.title}</span></div>
        <div className="pdf-controls" aria-label="ควบคุมหน้าเอกสาร">
          <button className="icon-button" type="button" onClick={() => onPageChange((page) => Math.max(1, page - 1))} disabled={pageNumber <= 1} aria-label="หน้าก่อนหน้า" title="หน้าก่อนหน้า"><ChevronLeft size={20} /></button>
          <output aria-live="polite">หน้า {pageNumber} / {pageCount || '…'}</output>
          <button className="icon-button" type="button" onClick={() => onPageChange((page) => Math.min(pageCount, page + 1))} disabled={!pageCount || pageNumber >= pageCount} aria-label="หน้าถัดไป" title="หน้าถัดไป"><ChevronRight size={20} /></button>
          <a className="icon-button" href={pdfDocument.file} target="_blank" rel="noreferrer" aria-label="เปิด PDF ต้นฉบับ"><ExternalLink size={17} /></a>
          <button className="icon-button" type="button" onClick={onClose} aria-label="ปิดเอกสาร"><X size={21} /></button>
        </div>
      </div>
      <div className="pdf-canvas">
        {hasError ? (
          <p className="pdf-status" role="alert">เปิดเอกสารไม่สำเร็จ กรุณาลองเปิดไฟล์ PDF ต้นฉบับ</p>
        ) : (
          <PdfDocument
            file={pdfDocument.file}
            loading={<p className="pdf-status">กำลังโหลดเอกสาร…</p>}
            error={<p className="pdf-status" role="alert">เปิดเอกสารไม่สำเร็จ</p>}
            onLoadSuccess={({ numPages }) => onPageCountChange(numPages)}
            onLoadError={onError}
            onSourceError={onError}
          >
            <PdfPage
              pageNumber={pageNumber}
              width={Math.max(280, Math.min(1100, window.innerWidth - 40))}
              renderTextLayer={false}
              renderAnnotationLayer={false}
              loading={<p className="pdf-status">กำลังแสดงหน้า {pageNumber}…</p>}
            />
          </PdfDocument>
        )}
      </div>
    </dialog>
  );
}

export default PdfViewer;