-- MIGRAÇÃO DE PAGAMENTOS + RELATÓRIO ANUAL FORMICT
-- Execute no SQL Editor do projeto Supabase usado por Gestao_PI_IFSC_corrigido.
-- Compatível com a estrutura deste projeto: anuidades.numero_patente -> patentes.numero_patente.
-- Não apaga registros existentes.

BEGIN;

ALTER TABLE public.anuidades
    ADD COLUMN IF NOT EXISTS numero_patente text,
    ADD COLUMN IF NOT EXISTS numero_anuidade integer,
    ADD COLUMN IF NOT EXISTS descricao_pagamento text,
    ADD COLUMN IF NOT EXISTS valor numeric(12,2),
    ADD COLUMN IF NOT EXISTS data_pagamento date,
    ADD COLUMN IF NOT EXISTS ano_pagamento integer,
    ADD COLUMN IF NOT EXISTS status text;

-- Recalcula ano_pagamento para registros já pagos que têm data_pagamento.
UPDATE public.anuidades
SET ano_pagamento = EXTRACT(YEAR FROM data_pagamento)::integer
WHERE data_pagamento IS NOT NULL
  AND (ano_pagamento IS NULL OR ano_pagamento <> EXTRACT(YEAR FROM data_pagamento)::integer);

-- View consumida pelo módulo Relatórios FORMICT.
-- Recria somente a view (não altera nem apaga registros das tabelas).
DROP VIEW IF EXISTS public.vw_formict_pagamentos;
CREATE VIEW public.vw_formict_pagamentos AS
SELECT
    a.id AS id_pagamento,
    p.numero_patente,
    p.titulo,
    p.modalidade_pi,
    p.gestor,
    p.campus,
    p.status AS status_pi,
    a.numero_anuidade,
    a.descricao_pagamento,
    a.valor,
    a.data_pagamento,
    COALESCE(a.ano_pagamento, EXTRACT(YEAR FROM a.data_pagamento)::integer) AS ano_pagamento,
    a.status AS status_pagamento
FROM public.anuidades AS a
LEFT JOIN public.patentes AS p
    ON p.numero_patente::text = a.numero_patente::text
WHERE a.status = 'pago'
  AND a.data_pagamento IS NOT NULL;

COMMIT;

-- Conferência após executar:
-- SELECT * FROM public.vw_formict_pagamentos ORDER BY ano_pagamento DESC, data_pagamento DESC;
