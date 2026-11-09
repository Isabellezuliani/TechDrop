-- TechDrop - Banco de dados
-- Sistema para localizar pontos de coleta de lixo eletrônico em Sorocaba
-- Os dados de exemplo no final são FICTÍCIOS e devem ser substituídos
-- após o levantamento com as instituições parceiras.
 
-- Recomeça do zero a cada execução (apaga o banco antigo, se existir)
DROP DATABASE IF EXISTS techdrop;
CREATE DATABASE techdrop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE techdrop;
 
-- ---------------------------------------------------------------------
-- 1. USUÁRIO (morador, parceiro ou administrador)
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  senha_hash    VARCHAR(255) NOT NULL,
  cep           CHAR(8),
  perfil        ENUM('morador','parceiro','admin') NOT NULL DEFAULT 'morador',
  ativo         BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
 
-- ---------------------------------------------------------------------
-- 2. INSTITUIÇÃO PARCEIRA (empresas, ONGs, escolas, órgãos públicos)
-- ---------------------------------------------------------------------
CREATE TABLE instituicao_parceira (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(150) NOT NULL,
  tipo          ENUM('empresa','ong','escola','orgao_publico','comercio','outro') NOT NULL,
  cnpj          CHAR(14) UNIQUE,
  telefone      VARCHAR(20),
  email         VARCHAR(150),
  site          VARCHAR(200),
  usuario_id    INT NULL,                -- responsável pela conta do parceiro
  ativa         BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL
);
 
-- ---------------------------------------------------------------------
-- 3. PONTO DE COLETA
-- ---------------------------------------------------------------------
CREATE TABLE ponto_coleta (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  instituicao_id   INT NOT NULL,
  nome             VARCHAR(150) NOT NULL,
  logradouro       VARCHAR(150) NOT NULL,
  numero           VARCHAR(10),
  bairro           VARCHAR(80),
  cidade           VARCHAR(80) NOT NULL DEFAULT 'Sorocaba',
  uf               CHAR(2) NOT NULL DEFAULT 'SP',
  cep              CHAR(8) NOT NULL,
  latitude         DECIMAL(9,6),
  longitude        DECIMAL(9,6),
  telefone         VARCHAR(20),
  observacoes      VARCHAR(255),
  ativo            BOOLEAN NOT NULL DEFAULT TRUE,
  atualizado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (instituicao_id) REFERENCES instituicao_parceira(id),
  INDEX idx_ponto_cep (cep)
);
 
-- Horários de funcionamento (um registro por dia da semana)
CREATE TABLE horario_funcionamento (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  ponto_id      INT NOT NULL,
  dia_semana    TINYINT NOT NULL,        -- 0 = domingo ... 6 = sábado
  abre_as       TIME NOT NULL,
  fecha_as      TIME NOT NULL,
  FOREIGN KEY (ponto_id) REFERENCES ponto_coleta(id) ON DELETE CASCADE,
  UNIQUE KEY uq_ponto_dia (ponto_id, dia_semana)
);
 
-- ---------------------------------------------------------------------
-- 4. TIPO DE RESÍDUO ELETRÔNICO
-- ---------------------------------------------------------------------
CREATE TABLE tipo_residuo (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  nome                  VARCHAR(80) NOT NULL UNIQUE,
  categoria             ENUM('pilhas_baterias','celulares_acessorios','computadores',
                             'perifericos','eletrodomesticos','outros') NOT NULL,
  descricao             VARCHAR(255),
  orientacao_descarte   VARCHAR(255)
);
 
-- Quais tipos cada ponto aceita (N:N)
CREATE TABLE ponto_residuo (
  ponto_id      INT NOT NULL,
  residuo_id    INT NOT NULL,
  PRIMARY KEY (ponto_id, residuo_id),
  FOREIGN KEY (ponto_id)   REFERENCES ponto_coleta(id)  ON DELETE CASCADE,
  FOREIGN KEY (residuo_id) REFERENCES tipo_residuo(id)  ON DELETE CASCADE
);
 
-- ---------------------------------------------------------------------
-- 5. BUSCA (histórico de pesquisas por CEP + tipo de resíduo)
--    Serve para medir a demanda e priorizar novos pontos.
-- ---------------------------------------------------------------------
CREATE TABLE busca (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id       INT NULL,             -- pode ser anônima
  cep_informado    CHAR(8) NOT NULL,
  residuo_id       INT NOT NULL,
  qtd_resultados   INT NOT NULL DEFAULT 0,
  realizada_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL,
  FOREIGN KEY (residuo_id) REFERENCES tipo_residuo(id)
);
 
-- ---------------------------------------------------------------------
-- 6. QUESTIONÁRIO COM A POPULAÇÃO (projeto de extensão)
-- ---------------------------------------------------------------------
CREATE TABLE resposta_questionario (
  id                    INT AUTO_INCREMENT PRIMARY KEY,
  bairro                VARCHAR(80),
  residuo_id            INT NULL,
  forma_descarte        ENUM('lixo_comum','guarda_em_casa','ponto_de_coleta',
                             'devolve_loja','doa','outro') NOT NULL,
  conhece_pontos        BOOLEAN NOT NULL,
  principal_dificuldade VARCHAR(255),
  respondida_em         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (residuo_id) REFERENCES tipo_residuo(id) ON DELETE SET NULL
);
 
-- ---------------------------------------------------------------------
-- 7. CHAMADO DE SUPORTE (cadastro de usuário, dados, dúvidas)
-- ---------------------------------------------------------------------
CREATE TABLE chamado_suporte (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id     INT NULL,
  assunto        VARCHAR(150) NOT NULL,
  descricao      TEXT NOT NULL,
  status         ENUM('aberto','em_andamento','resolvido') NOT NULL DEFAULT 'aberto',
  aberto_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolvido_em   DATETIME NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuario(id) ON DELETE SET NULL
);
 
-- =====================================================================
-- DADOS DE EXEMPLO (fictícios)
-- =====================================================================
INSERT INTO tipo_residuo (nome, categoria, descricao, orientacao_descarte) VALUES
 ('Pilhas',               'pilhas_baterias',      'Pilhas comuns e recarregáveis', 'Entregar sem violar ou perfurar'),
 ('Baterias',             'pilhas_baterias',      'Baterias de celular, notebook e outras', 'Não descartar no lixo comum'),
 ('Celulares',            'celulares_acessorios', 'Aparelhos celulares', 'Retirar chip e apagar os dados antes'),
 ('Carregadores e cabos', 'celulares_acessorios', 'Carregadores, cabos e fones', NULL),
 ('Computadores',         'computadores',         'Desktops, notebooks e tablets', 'Apagar os dados antes de entregar'),
 ('Periféricos',          'perifericos',          'Teclado, mouse, impressora, monitor', NULL);
 
INSERT INTO instituicao_parceira (nome, tipo, email) VALUES
 ('Parceiro Exemplo A (fictício)', 'empresa', 'contato@exemploa.example'),
 ('Parceiro Exemplo B (fictício)', 'escola',  'contato@exemplob.example');
 
INSERT INTO ponto_coleta (instituicao_id, nome, logradouro, numero, bairro, cep) VALUES
 (1, 'Ponto de Exemplo 1', 'Rua Exemplo', '100', 'Centro', '18000000'),
 (2, 'Ponto de Exemplo 2', 'Av. Exemplo',  '200', 'Campolim', '18047000');
 
INSERT INTO ponto_residuo (ponto_id, residuo_id) VALUES
 (1,1),(1,2),(1,3),(2,3),(2,5),(2,6);
 
INSERT INTO horario_funcionamento (ponto_id, dia_semana, abre_as, fecha_as) VALUES
 (1,1,'08:00','17:00'),(1,2,'08:00','17:00'),(1,3,'08:00','17:00'),
 (2,1,'09:00','18:00'),(2,5,'09:00','18:00');
 
-- =====================================================================
-- CONSULTAS PRINCIPAIS DO PROTÓTIPO
-- =====================================================================
 
-- A) Tela "Buscar ponto": pontos ativos que aceitam o resíduo escolhido
--    (troque o nome do resíduo; a ordenação por proximidade pode usar
--     latitude/longitude do CEP informado quando o mapa for implementado)
SELECT p.nome, p.logradouro, p.numero, p.bairro, p.cep, p.telefone,
       i.nome AS instituicao
FROM ponto_coleta p
JOIN instituicao_parceira i ON i.id = p.instituicao_id
JOIN ponto_residuo pr       ON pr.ponto_id = p.id
JOIN tipo_residuo r         ON r.id = pr.residuo_id
WHERE p.ativo = TRUE AND i.ativa = TRUE
  AND r.nome = 'Celulares'
ORDER BY p.bairro, p.nome;
 
-- B) Horários de um ponto
SELECT dia_semana, abre_as, fecha_as
FROM horario_funcionamento
WHERE ponto_id = 1
ORDER BY dia_semana;
 
-- C) Resíduos mais procurados (apoia o Marketing e novos parceiros)
SELECT r.nome, COUNT(*) AS total_buscas
FROM busca b
JOIN tipo_residuo r ON r.id = b.residuo_id
GROUP BY r.nome
ORDER BY total_buscas DESC;
 
-- D) Buscas sem resultado (onde faltam pontos de coleta)
SELECT cep_informado, r.nome AS residuo, COUNT(*) AS vezes
FROM busca b
JOIN tipo_residuo r ON r.id = b.residuo_id
WHERE b.qtd_resultados = 0
GROUP BY cep_informado, r.nome
ORDER BY vezes DESC;
 
-- E) Questionário: % da população que conhece pontos de descarte
SELECT ROUND(100 * AVG(conhece_pontos), 1) AS percentual_conhece
FROM resposta_questionario;

-- Resíduos que têm orientação de descarte
SELECT nome, categoria, orientacao_descarte
FROM tipo_residuo
WHERE orientacao_descarte IS NOT NULL
ORDER BY categoria, nome;

-- 2. Pontos de coleta com a instituição responsável
SELECT p.nome AS ponto,
       p.logradouro, p.numero, p.bairro, p.cep,
       i.nome AS instituicao,
       i.tipo AS tipo_instituicao
FROM ponto_coleta p
JOIN instituicao_parceira i ON i.id = p.instituicao_id
ORDER BY p.bairro;

-- 3. Resíduos aceitos por cada ponto
SELECT p.nome AS ponto,
       p.cep,
       GROUP_CONCAT(r.nome ORDER BY r.nome SEPARATOR ', ') AS residuos_aceitos
FROM ponto_coleta p
JOIN ponto_residuo pr ON pr.ponto_id = p.id
JOIN tipo_residuo r   ON r.id = pr.residuo_id
GROUP BY p.id, p.nome, p.cep;