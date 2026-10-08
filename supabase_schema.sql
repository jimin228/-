-- ========================================================
-- 📋 외근 관리 대장 - Supabase DB 구축용 SQL 스크립트 (에러 방지 및 재실행 안전 버전)
-- ========================================================
-- 💡 사용 방법:
-- 1. Supabase 대시보드 (https://supabase.com/dashboard) 로그인
-- 2. 본인 프로젝트 선택 후 좌측 메뉴 [SQL Editor] 클릭
-- 3. [New query] 클릭 후 이 내용 전체를 붙여넣고 [Run] 실행
-- ========================================================

-- 1. 외근 내역 테이블 생성 (outwork_records)
CREATE TABLE IF NOT EXISTS public.outwork_records (
    id TEXT PRIMARY KEY,                       -- 외근 고유 ID (예: rec-1728374...)
    date TEXT NOT NULL,                        -- 외근 일자 (YYYY-MM-DD 형식)
    team TEXT NOT NULL,                        -- 팀 번호 ('1', '2', '3', '4')
    name TEXT NOT NULL,                        -- 성명
    position TEXT DEFAULT '',                  -- 직급
    destination TEXT NOT NULL,                 -- 방문처 / 행선지
    purpose TEXT NOT NULL,                     -- 외근 목적
    start_time TEXT NOT NULL,                  -- 출발 시간 (HH:MM)
    end_time TEXT DEFAULT '',                  -- 복귀(예정) 시간 (HH:MM)
    transport TEXT DEFAULT '대중교통',          -- 이동 수단
    status TEXT DEFAULT '외근중',               -- 진행 상태 ('외근중', '복귀완료')
    companion TEXT DEFAULT '',                 -- 동행자
    expense NUMERIC DEFAULT 0,                 -- 예상 경비 (원)
    note TEXT DEFAULT '',                      -- 비고 / 연락처
    created_at TIMESTAMPTZ DEFAULT NOW(),      -- 등록 일시
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

-- 기본 팀명 데이터 삽입 (기존 데이터가 있으면 유지)
INSERT INTO public.outwork_team_configs (id, team1, team2, team3, team4)
VALUES ('config_main', '1팀', '2팀', '3팀', '4팀')
ON CONFLICT (id) DO NOTHING;

-- 3. RLS(행 단위 보안) 활성화
ALTER TABLE public.outwork_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outwork_team_configs ENABLE ROW LEVEL SECURITY;

-- 4. 보안 정책(Policy) 중복 에러 방지 처리 (기존 정책이 있으면 삭제 후 재생성)
DROP POLICY IF EXISTS "Public Read Outwork Records" ON public.outwork_records;
DROP POLICY IF EXISTS "Public Insert Outwork Records" ON public.outwork_records;
DROP POLICY IF EXISTS "Public Update Outwork Records" ON public.outwork_records;
DROP POLICY IF EXISTS "Public Delete Outwork Records" ON public.outwork_records;
DROP POLICY IF EXISTS "Public All Access Outwork Records" ON public.outwork_records;

-- 외근 내역 전체 접근(조회/등록/수정/삭제) 허용 정책
CREATE POLICY "Public All Access Outwork Records" 
ON public.outwork_records 
FOR ALL 
USING (true) 
WITH CHECK (true);

DROP POLICY IF EXISTS "Public Read Team Config" ON public.outwork_team_configs;
DROP POLICY IF EXISTS "Public Update Team Config" ON public.outwork_team_configs;
DROP POLICY IF EXISTS "Public All Access Team Config" ON public.outwork_team_configs;

-- 팀 설정 전체 접근 허용 정책
CREATE POLICY "Public All Access Team Config" 
ON public.outwork_team_configs 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 5. 실시간(Realtime) 복제 publication 등록 (이미 등록되어 있거나 오류 발생 시에도 안전하게 통과)
DO $$ 
BEGIN
  -- outwork_records 실시간 추가 시도
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'outwork_records'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.outwork_records;
    END IF;

    -- outwork_team_configs 실시간 추가 시도
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' 
      AND schemaname = 'public' 
      AND tablename = 'outwork_team_configs'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.outwork_team_configs;
    END IF;
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- 실시간 테이블 등록 시 발생하는 중복/권한 에러는 안전하게 건너뜁니다
  NULL;
END $$;

-- 6. 초기 샘플 데이터 등록 (기존 데이터 유지)
INSERT INTO public.outwork_records (id, date, team, name, position, destination, purpose, start_time, end_time, transport, status, companion, expense, note)
VALUES 
  ('rec-sample-1', TO_CHAR(NOW(), 'YYYY-MM-DD'), '1', '김민수', '팀장', '(주)미래솔루션 여의도 본사', 'Q4 시스템 유지보수 정기 회의', '10:00', '13:30', '대중교통', '복귀완료', '이지원 대리', 15000, '010-1234-5678'),
  ('rec-sample-2', TO_CHAR(NOW(), 'YYYY-MM-DD'), '2', '박서준', '과장', '한국테크 판교 R&D 센터', '신규 기술 스펙 검토 및 협업 미팅', '13:00', '17:30', '법인차량', '외근중', '', 28000, '차량: 12가 3456 / 유류비 포함'),
  ('rec-sample-3', TO_CHAR(NOW(), 'YYYY-MM-DD'), '3', '최유진', '대리', '서울시청 스마트도시과', '공공 입찰 제안서 제출 및 대면 설명', '14:00', '16:30', '대중교통', '외근중', '', 6500, '제안서 원본 지참')
ON CONFLICT (id) DO NOTHING;
