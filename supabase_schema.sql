-- ========================================================
-- 📋 외근 관리 대장 (Supabase DB 구축용 SQL 스크립트)
-- ========================================================
-- 사용 방법:
-- 1. Supabase 대시보드 (https://supabase.com/dashboard)에 로그인합니다.
-- 2. 본인의 프로젝트를 선택 후 좌측 메뉴의 [SQL Editor]를 클릭합니다.
-- 3. [New query]를 누르고 아래 스크립트 전체를 복사하여 붙여넣은 뒤, [Run] 버튼을 누릅니다.
-- ========================================================

-- 1. 외근 내역 테이블 생성 (outwork_records)
CREATE TABLE IF NOT EXISTS public.outwork_records (
    id TEXT PRIMARY KEY,                       -- 외근 고유 ID (예: rec-1728374...)
    date DATE NOT NULL,                        -- 외근 일자
    team TEXT NOT NULL,                        -- 팀 번호 ('1', '2', '3', '4')
    name TEXT NOT NULL,                        -- 성명
    position TEXT,                             -- 직급
    destination TEXT NOT NULL,                 -- 방문처 / 행선지
    purpose TEXT NOT NULL,                     -- 외근 목적
    start_time TEXT NOT NULL,                  -- 출발 시간 (HH:MM)
    end_time TEXT,                             -- 복귀(예정) 시간 (HH:MM)
    transport TEXT DEFAULT '대중교통',          -- 이동 수단
    status TEXT DEFAULT '외근중',               -- 진행 상태 ('외근중', '복귀완료')
    companion TEXT,                            -- 동행자
    expense NUMERIC DEFAULT 0,                 -- 예상 경비 (원)
    note TEXT,                                 -- 비고 / 연락처
    created_at TIMESTAMPTZ DEFAULT NOW(),      -- 생성 일시
    updated_at TIMESTAMPTZ DEFAULT NOW()       -- 수정 일시
);

-- 2. 팀 설정 테이블 생성 (outwork_team_configs)
CREATE TABLE IF NOT EXISTS public.outwork_team_configs (
    id TEXT PRIMARY KEY DEFAULT 'config_main', -- 설정 고유 ID
    team1 TEXT DEFAULT '1팀',
    team2 TEXT DEFAULT '2팀',
    team3 TEXT DEFAULT '3팀',
    team4 TEXT DEFAULT '4팀',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 초기 기본 팀 설정 데이터 삽입
INSERT INTO public.outwork_team_configs (id, team1, team2, team3, team4)
VALUES ('config_main', '1팀', '2팀', '3팀', '4팀')
ON CONFLICT (id) DO NOTHING;

-- 3. RLS(행 단위 보안) 활성화 및 전체 읽기/쓰기 권한 허용 (사내 공용 대장용)
ALTER TABLE public.outwork_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outwork_team_configs ENABLE ROW LEVEL SECURITY;

-- 외근 내역 RLS 정책 (anon 공개 키로 조회/추가/수정/삭제 허용)
CREATE POLICY "Public Read Outwork Records" 
ON public.outwork_records FOR SELECT USING (true);

CREATE POLICY "Public Insert Outwork Records" 
ON public.outwork_records FOR INSERT WITH CHECK (true);

CREATE POLICY "Public Update Outwork Records" 
ON public.outwork_records FOR UPDATE USING (true);

CREATE POLICY "Public Delete Outwork Records" 
ON public.outwork_records FOR DELETE USING (true);

-- 팀 설정 RLS 정책
CREATE POLICY "Public Read Team Config" 
ON public.outwork_team_configs FOR SELECT USING (true);

CREATE POLICY "Public Update Team Config" 
ON public.outwork_team_configs FOR ALL USING (true);

-- 4. 실시간(Realtime) 동기화 활성화
-- 여러 사용자가 동시에 열람할 때 새로고침 없이 즉시 반영되도록 실시간 복제 테이블에 추가합니다.
ALTER PUBLICATION supabase_realtime ADD TABLE public.outwork_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.outwork_team_configs;

-- 5. 샘플 초기 데이터 추가 (선택 사항)
INSERT INTO public.outwork_records (id, date, team, name, position, destination, purpose, start_time, end_time, transport, status, companion, expense, note)
VALUES 
  ('rec-sample-1', CURRENT_DATE, '1', '김민수', '팀장', '(주)미래솔루션 여의도 본사', 'Q4 시스템 유지보수 정기 회의', '10:00', '13:30', '대중교통', '복귀완료', '이지원 대리', 15000, '010-1234-5678'),
  ('rec-sample-2', CURRENT_DATE, '2', '박서준', '과장', '한국테크 판교 R&D 센터', '신규 기술 스펙 검토 및 협업 미팅', '13:00', '17:30', '법인차량', '외근중', '', 28000, '차량: 12가 3456 / 유류비 포함'),
  ('rec-sample-3', CURRENT_DATE, '3', '최유진', '대리', '서울시청 스마트도시과', '공공 입찰 제안서 제출 및 대면 설명', '14:00', '16:30', '대중교통', '외근중', '', 6500, '제안서 원본 지참')
ON CONFLICT (id) DO NOTHING;
