import React, { Suspense, lazy, useEffect, useRef, useState } from 'react';
import diagramImage from '../file/diagram.svg';
import githubLogo from '../file/github-logo.png';
import keyFeaturesPdf from '../file/key-features.pdf';
import kmutnbLogo from '../file/kmutnb-logo.png';
import securityReportPdf from '../file/security-design-report.pdf';
import {
  ArrowDownRight,
  ArrowUpRight,
  Cloud,
  ExternalLink,
  FileText,
  Image,
  LockKeyhole,
  Maximize2,
  Menu,
  RotateCcw,
  Network,
  Server,
  UsersRound,
  ZoomIn,
  ZoomOut,
  X,
} from 'lucide-react';

const PdfViewer = lazy(() => import('./PdfViewer.jsx'));
const PdfPagePreview = lazy(() => import('./PdfViewer.jsx').then((module) => ({ default: module.PdfPagePreview })));

const membersEndpoint = '/members';
const githubUrl = 'https://github.com/thapanee2542/secure-3tier-cloud-app.git';

const documents = [
  {
    number: 'A',
    title: 'Key Features',
    description: 'ภาพรวมคุณสมบัติและองค์ประกอบของเว็บแอปพลิเคชัน',
    file: keyFeaturesPdf,
    fileName: 'key-features.pdf',
  },
  {
    number: 'B',
    title: 'Security Design Report',
    description: 'รายละเอียดการออกแบบระบบและแนวทางด้านความปลอดภัย',
    file: securityReportPdf,
    fileName: 'security-design-report.pdf',
  },
];

function SectionHeading({ eyebrow, title, description, id }) {
  return (
    <div className="section-heading" id={id}>
      {eyebrow && <span className="eyebrow">{eyebrow}</span>}
      <div className="heading-row">
        <h2>{title}</h2>
        {description && <p>{description}</p>}
      </div>
    </div>
  );
}

function DeferredPdfPreview({ document, onOpen }) {
  const [shouldRender, setShouldRender] = useState(false);
  const previewRef = useRef(null);

  useEffect(() => {
    const element = previewRef.current;
    if (!element || shouldRender) return undefined;

    if (!('IntersectionObserver' in window)) {
      setShouldRender(true);
      return undefined;
    }

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setShouldRender(true);
        observer.disconnect();
      }
    }, { rootMargin: '240px' });
    observer.observe(element);
    return () => observer.disconnect();
  }, [shouldRender]);

  return (
    <div className="pdf-preview-slot" ref={previewRef}>
      {shouldRender ? (
        <Suspense fallback={<div className="pdf-preview-placeholder"><FileText size={25} /><span>กำลังเตรียมตัวอย่าง PDF…</span></div>}>
          <PdfPagePreview file={document.file} />
        </Suspense>
      ) : (
        <div className="pdf-preview-placeholder"><FileText size={25} /><span>PDF · กำลังเตรียมตัวอย่าง</span></div>
      )}
    </div>
  );
}

function observeActiveSection(onActiveSectionChange) {
  const sectionIds = ['architecture', 'features', 'members'];
  let clickedSection = null;
  let releaseTimer;

  const updateActiveSection = () => {
    // ระหว่างเลื่อนไปยังเมนูที่กด ให้คงสีเมนูนั้นไว้
    if (clickedSection) return;

    const sections = sectionIds
      .map((id) => document.getElementById(id))
      .filter(Boolean);

    if (!sections.length) return;

    const pageHeight = document.documentElement.scrollHeight;
    const canScroll = pageHeight > window.innerHeight;
    const isAtBottom =
      window.scrollY + window.innerHeight >= pageHeight - 4;

    // Members อยู่ท้ายหน้า อาจเลื่อนขึ้นไปถึงด้านบนไม่ได้
    if (canScroll && isAtBottom) {
      onActiveSectionChange(sections[sections.length - 1].id);
      return;
    }

    const header = document.querySelector('.site-header');
    const activationLine =
      Math.max(0, header?.getBoundingClientRect().bottom ?? 0) + 32;

    let currentSection = sections[0].id;

    for (const section of sections) {
      if (section.getBoundingClientRect().top <= activationLine) {
        currentSection = section.id;
      }
    }

    onActiveSectionChange(currentSection);
  };

  const releaseClickedSection = () => {
    clickedSection = null;
  };

  const onScroll = () => {
    if (clickedSection) {
      clearTimeout(releaseTimer);
      releaseTimer = window.setTimeout(releaseClickedSection, 180);
      return;
    }

    updateActiveSection();
  };

  const onClick = (event) => {
    if (
      event.defaultPrevented ||
      event.button !== 0 ||
      event.ctrlKey ||
      event.metaKey ||
      event.shiftKey ||
      event.altKey
    ) {
      return;
    }

    const link = event.target.closest('a[href^="#"]');
    const sectionId = link?.getAttribute('href')?.slice(1);

    if (!sectionIds.includes(sectionId)) return;

    clickedSection = sectionId;
    onActiveSectionChange(sectionId);

    clearTimeout(releaseTimer);

    // กรณีกดเมนูของ section ที่อยู่ตรงนั้นแล้ว ไม่มี scroll เกิดขึ้น
    releaseTimer = window.setTimeout(releaseClickedSection, 1200);
  };

  document.addEventListener('click', onClick);
  window.addEventListener('scroll', onScroll, { passive: true });
  window.addEventListener('resize', updateActiveSection);

  updateActiveSection();

  return () => {
    clearTimeout(releaseTimer);
    document.removeEventListener('click', onClick);
    window.removeEventListener('scroll', onScroll);
    window.removeEventListener('resize', updateActiveSection);
  };
}

function App() {
  const [members, setMembers] = useState([]);
  const [membersState, setMembersState] = useState('idle');
  const [diagramOpen, setDiagramOpen] = useState(false);
  const [diagramZoom, setDiagramZoom] = useState(1);
  const [diagramDragging, setDiagramDragging] = useState(false);
  const [activeDocument, setActiveDocument] = useState(null);
  const [pdfPage, setPdfPage] = useState(1);
  const [pdfPageCount, setPdfPageCount] = useState(0);
  const [pdfError, setPdfError] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeSection, setActiveSection] = useState('architecture');
  const diagramCanvasRef = useRef(null);
  const diagramDragRef = useRef(null);

  useEffect(() => {
    if (!diagramOpen) return undefined;
    const onKeyDown = (event) => {
      if (event.key === 'Escape') setDiagramOpen(false);
      if (event.key === '+' || event.key === '=') {
        setDiagramZoom((zoom) => Math.min(3, Math.round((zoom + 0.25) * 100) / 100));
      }
      if (event.key === '-') {
        setDiagramZoom((zoom) => Math.max(0.5, Math.round((zoom - 0.25) * 100) / 100));
      }
      if (event.key === '0') setDiagramZoom(1);
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [diagramOpen]);

  useEffect(() => {
    if (!diagramOpen || !diagramCanvasRef.current) return undefined;

    const canvas = diagramCanvasRef.current;
    const onWheel = (event) => {
      if (!event.ctrlKey) return;
      event.preventDefault();
      const zoomChange = event.deltaY < 0 ? 0.25 : -0.25;
      const nextZoom = Math.min(3, Math.max(0.5, Math.round((diagramZoom + zoomChange) * 100) / 100));
      if (nextZoom === diagramZoom) return;

      const bounds = canvas.getBoundingClientRect();
      const pointerX = event.clientX - bounds.left;
      const pointerY = event.clientY - bounds.top;
      setDiagramZoom(nextZoom);
      requestAnimationFrame(() => {
        const scale = nextZoom / diagramZoom;
        canvas.scrollLeft = (canvas.scrollLeft + pointerX) * scale - pointerX;
        canvas.scrollTop = (canvas.scrollTop + pointerY) * scale - pointerY;
      });
    };

    canvas.addEventListener('wheel', onWheel, { passive: false });
    return () => canvas.removeEventListener('wheel', onWheel);
  }, [diagramOpen, diagramZoom]);

  useEffect(() => {
    if (!activeDocument) return undefined;

    const onKeyDown = (event) => {
      if (event.key === 'Escape') setActiveDocument(null);
      if (event.key === 'ArrowLeft') setPdfPage((page) => Math.max(1, page - 1));
      if (event.key === 'ArrowRight') setPdfPage((page) => Math.min(pdfPageCount, page + 1));
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [activeDocument, pdfPageCount]);

  useEffect(() => observeActiveSection(setActiveSection), []);

  async function loadMembers() {
    setMembersState('loading');
    try {
      const response = await fetch(membersEndpoint);
      if (!response.ok) throw new Error(`Request failed: ${response.status}`);
      const data = await response.json();
      const fetchedMembers = Array.isArray(data) ? data : data?.members;
      if (!Array.isArray(fetchedMembers)) throw new Error('Unexpected members response');
      setMembers(fetchedMembers);
      setMembersState('success');
    } catch {
      setMembers([]);
      setMembersState('error');
    }
  }

  const openDiagram = () => {
    setDiagramZoom(1);
    setDiagramOpen(true);
  };

  const openDocument = (document) => {
    setActiveDocument(document);
    setPdfPage(1);
    setPdfPageCount(0);
    setPdfError(false);
  };

  const changeDiagramZoom = (amount) => {
    setDiagramZoom((zoom) => Math.min(3, Math.max(0.5, Math.round((zoom + amount) * 100) / 100)));
  };

  const startDiagramDrag = (event) => {
    if (diagramZoom <= 1 || (event.pointerType === 'mouse' && event.button !== 0)) return;
    event.preventDefault();
    diagramDragRef.current = {
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      startScrollLeft: event.currentTarget.scrollLeft,
      startScrollTop: event.currentTarget.scrollTop,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    setDiagramDragging(true);
  };

  const moveDiagram = (event) => {
    const drag = diagramDragRef.current;
    if (!drag || drag.pointerId !== event.pointerId) return;
    event.currentTarget.scrollLeft = drag.startScrollLeft - (event.clientX - drag.startX);
    event.currentTarget.scrollTop = drag.startScrollTop - (event.clientY - drag.startY);
  };

  const stopDiagramDrag = (event) => {
    if (!diagramDragRef.current || diagramDragRef.current.pointerId !== event.pointerId) return;
    diagramDragRef.current = null;
    setDiagramDragging(false);
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
  };

  const closeMenu = () => setMenuOpen(false);
  let membersButtonLabel = 'แสดงสมาชิกในกลุ่ม';
  if (membersState === 'loading') membersButtonLabel = 'กำลังโหลด...';
  if (membersState === 'success') membersButtonLabel = 'โหลดข้อมูลอีกครั้ง';
  if (membersState === 'error') membersButtonLabel = 'ลองโหลดข้อมูลอีกครั้ง';

  return (
    <>
      <header className="site-header">
        <a className="brand" href="#top" aria-label="Cloud Security, กลับไปหน้าแรก" onClick={closeMenu}>
          <img src={kmutnbLogo} alt="ตรามหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ" />
          <span className="brand-copy">
            <strong>Cloud Security</strong>
            <span>070315221 <i /> TERM PROJECT</span>
          </span>
        </a>
        <button
          className="menu-toggle icon-button"
          type="button"
          aria-label={menuOpen ? 'ปิดเมนู' : 'เปิดเมนู'}
          aria-expanded={menuOpen}
          aria-controls="main-navigation"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          {menuOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
        <nav id="main-navigation" className={menuOpen ? 'main-nav is-open' : 'main-nav'} aria-label="เมนูหลัก">
          <a className={activeSection === 'architecture' ? 'is-active' : ''} aria-current={activeSection === 'architecture' ? 'location' : undefined} href="#architecture" onClick={closeMenu}>Architecture</a>
          <a className={activeSection === 'features' ? 'is-active' : ''} aria-current={activeSection === 'features' ? 'location' : undefined} href="#features" onClick={closeMenu}>Key Features &amp; Security Report</a>
          <a className={activeSection === 'members' ? 'is-active' : ''} aria-current={activeSection === 'members' ? 'location' : undefined} href="#members" onClick={closeMenu}>Members</a>
        </nav>
        <a className="github-link" href={githubUrl} target="_blank" rel="noreferrer" aria-label="เปิด GitHub repository">
          <img src={githubLogo} alt="" />
          <ExternalLink size={13} />
        </a>
      </header>

      <main id="top">
        <section className="hero section-wrap">
          <div className="hero-copy">
            <div className="hero-label"><Cloud size={15} /> Cloud Security Project</div>
            <h1>ออกแบบเว็บให้ปลอดภัย<br /><em>ตั้งแต่โครงสร้าง</em></h1>
            <p className="hero-description">Secure 3-Tier Web Application on Cloud</p>
            <div className="hero-actions">
              <a className="button button-dark" href="#architecture">สำรวจสถาปัตยกรรม <ArrowDownRight size={17} /></a>
              <a className="text-link" href="#features">อ่านรายงาน <ArrowUpRight size={15} /></a>
            </div>
            <div className="hero-meta"><span>รายวิชา 070315221</span><span>มหาวิทยาลัยเทคโนโลยีพระจอมเกล้าพระนครเหนือ</span></div>
          </div>
          <div className="hero-art" aria-label="สรุปสถาปัตยกรรมระบบสามชั้น">
            <div className="art-topline"><span>PROJECT OVERVIEW</span><span>THREE-TIER ARCHITECTURE</span></div>
            <div className="art-stack">
              <div className="stack-layer web-layer"><div className="layer-symbol"><Network size={19} /></div><div><small>01 / PRESENTATION</small><strong>Web Tier</strong></div></div>
              <div className="stack-layer app-layer"><div className="layer-symbol"><Server size={19} /></div><div><small>02 / APPLICATION</small><strong>Application Tier</strong></div></div>
              <div className="stack-layer db-layer"><div className="layer-symbol"><LockKeyhole size={19} /></div><div><small>03 / DATA</small><strong>Data Tier</strong></div></div>
            </div>
          </div>
        </section>

        <section className="architecture-section" id="architecture">
          <div className="section-wrap">
            <h2 className="architecture-title">Architecture Diagram</h2>
            <button className="diagram-preview" type="button" onClick={openDiagram} aria-label="ขยายแผนภาพสถาปัตยกรรม">
              <div className="diagram-toolbar"><span>SVG · CLICK TO EXPAND <Maximize2 size={14} /></span></div>
              <img src={diagramImage} alt="แผนภาพสถาปัตยกรรม Secure 3-Tier Web Application" />
              <span className="diagram-expand"><Maximize2 size={15} /> ขยายแผนภาพ</span>
            </button>
          </div>
        </section>

        <section className="documents-section section-wrap" id="features">
          <div className="documents-heading">
            <div>
              <span className="eyebrow">PROJECT DOCUMENTS</span>
              <h2>Key Features &amp; Security Report</h2>
            </div>
            <p>เอกสารประกอบโครงงาน</p>
          </div>

          <div className="document-grid">
            {documents.map((document, index) => (
              <article className="document-card" key={document.number}>
                <DeferredPdfPreview
                  document={document}
                  onOpen={() => openDocument(document)}
                />

                <div className="document-copy">
                  <span className="document-kicker">
                    <FileText size={15} />
                    {index === 0 ? 'KEY FEATURES' : 'SECURITY REPORT'}
                  </span>

                  <h3>{document.title}</h3>
                  <p>{document.description}</p>

                  <div className="document-actions">
                    <button
                      className="button button-primary"
                      type="button"
                      onClick={() => openDocument(document)}
                    >
                      เปิดอ่าน <ArrowUpRight size={15} />
                    </button>

                    <a
                      className="download-link"
                      href={document.file}
                      download={document.fileName}
                      aria-label={`ดาวน์โหลด ${document.title}`}
                    >
                      <ArrowDownRight size={16} /> ดาวน์โหลด
                    </a>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section className="members-section section-wrap" id="members">
          <div className="members-heading">
            <SectionHeading title="ทีมผู้พัฒนา" />
            <button className="button button-outline" type="button" onClick={loadMembers} disabled={membersState === 'loading'}>
              <UsersRound size={17} /> {membersButtonLabel}
            </button>
          </div>
          {membersState === 'idle' && <div className="members-prompt"><span>5</span><p>สมาชิกในทีม</p><span className="prompt-rule" /><p>กดเพื่อโหลดข้อมูลจาก API</p><ArrowDownRight size={16} /></div>}
          {membersState === 'loading' && <output className="members-loading"><span className="members-spinner" />กำลังโหลดข้อมูลสมาชิก…</output>}
          {membersState === 'error' && <div className="members-message error-message" role="alert">โหลดข้อมูลไม่สำเร็จ กรุณาลองอีกครั้ง หรือตรวจสอบการเชื่อมต่อเครือข่าย</div>}
          {membersState === 'success' && members.length === 0 && <div className="members-message">ยังไม่มีข้อมูลสมาชิก</div>}
          {membersState === 'success' && members.length > 0 && (
            <div className="member-grid">
              {members.map((member, index) => (
                <article className="member-row" key={member.memberId ?? member.studentId ?? index}>
                  {member.imagePath ? (
                    <>
                      <img className="member-avatar" src={member.imagePath} alt="" loading="lazy" onError={(event) => { event.currentTarget.hidden = true; event.currentTarget.nextElementSibling.hidden = false; }} />
                      <span className="member-avatar member-avatar-placeholder" aria-hidden="true" hidden><Image size={26} /></span>
                    </>
                  ) : <span className="member-avatar member-avatar-placeholder" aria-hidden="true"><Image size={26} /></span>}
                  <span className="member-details"><strong>{member.name ?? 'สมาชิกทีม'}</strong><span className="member-id">{member.studentId ?? member.memberId ?? `0${index + 1}`}</span></span>
                </article>
              ))}
            </div>
          )}
        </section>
      </main>

      <footer className="site-footer">
        <div className="section-wrap footer-inner">
          <div className="footer-brand"><img src={kmutnbLogo} alt="" /><span>KMUTNB <i /> CLOUD SECURITY</span></div>
          <p>Secure 3-Tier Web Application on Cloud</p>
          <a href={githubUrl} target="_blank" rel="noreferrer">VIEW SOURCE <ArrowUpRight size={14} /></a>
        </div>
      </footer>

      {diagramOpen && (
        <dialog open className="diagram-modal" aria-modal="true" aria-label="แผนภาพสถาปัตยกรรม">
          <div className="modal-toolbar" aria-label="เครื่องมือแผนภาพ">
            <div className="modal-controls" aria-label="ควบคุมการซูมแผนภาพ">
              <button className="icon-button" type="button" onClick={() => changeDiagramZoom(-0.25)} disabled={diagramZoom <= 0.5} aria-label="ซูมออก" title="ซูมออก"><ZoomOut size={18} /></button>
              <output aria-live="polite">{Math.round(diagramZoom * 100)}%</output>
              <button className="icon-button" type="button" onClick={() => changeDiagramZoom(0.25)} disabled={diagramZoom >= 3} aria-label="ซูมเข้า" title="ซูมเข้า"><ZoomIn size={18} /></button>
              <button className="icon-button" type="button" onClick={() => setDiagramZoom(1)} aria-label="คืนขนาดเดิม" title="คืนขนาดเดิม"><RotateCcw size={17} /></button>
            </div>
            <button className="icon-button" type="button" onClick={() => setDiagramOpen(false)} aria-label="ปิดแผนภาพ"><X size={21} /></button>
          </div>
          <div
            ref={diagramCanvasRef}
            className={`modal-canvas${diagramZoom > 1 ? ' is-zoomed' : ''}${diagramDragging ? ' is-dragging' : ''}`}
            onPointerDown={startDiagramDrag}
            onPointerMove={moveDiagram}
            onPointerUp={stopDiagramDrag}
            onPointerCancel={stopDiagramDrag}
          >
            <img src={diagramImage} alt="แผนภาพสถาปัตยกรรม Secure 3-Tier Web Application" draggable="false" style={{ width: `${diagramZoom * 100}%`, height: 'auto' }} />
          </div>
        </dialog>
      )}

      {activeDocument && (
        <Suspense fallback={<div className="pdf-viewer pdf-loading">กำลังเตรียมตัวอ่าน PDF…</div>}>
          <PdfViewer
            key={activeDocument.number}
            pdfDocument={activeDocument}
            pageNumber={pdfPage}
            pageCount={pdfPageCount}
            hasError={pdfError}
            onPageChange={setPdfPage}
            onPageCountChange={setPdfPageCount}
            onError={() => setPdfError(true)}
            onClose={() => setActiveDocument(null)}
          />
        </Suspense>
      )}
    </>
  );
}

export default App;