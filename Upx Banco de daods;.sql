-- PROJETO TECHDROP - BANCO DE DADOS

-- 1. Criação do Banco de Dados
DROP DATABASE IF EXISTS techdrop;
CREATE DATABASE techdrop;
USE techdrop;

-- Tabela de Tipos de Resíduos
CREATE TABLE tipo_residuo (
    id_tipo INT PRIMARY KEY AUTO_INCREMENT,
    nome_tipo VARCHAR(100) NOT NULL
);

-- Tabela de Pontos de Coleta
CREATE TABLE ponto_coleta (
    id_ponto INT PRIMARY KEY AUTO_INCREMENT,
    nome_ponto VARCHAR(150) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    endereco VARCHAR(255) NOT NULL,
    horario_funcionamento VARCHAR(100) NOT NULL
);

-- Tabela de Ligação (Quais pontos aceitam quais resíduos)
CREATE TABLE ponto_residuo (
    id_ponto INT,
    id_tipo INT,
    PRIMARY KEY (id_ponto, id_tipo),
    FOREIGN KEY (id_ponto) REFERENCES ponto_coleta(id_ponto),
    FOREIGN KEY (id_tipo) REFERENCES tipo_residuo(id_tipo)
);

-- Tabela de Histórico de Buscas
CREATE TABLE busca (
    id_busca INT PRIMARY KEY AUTO_INCREMENT,
    cep_digitado VARCHAR(9) NOT NULL,
    id_tipo INT,
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_tipo) REFERENCES tipo_residuo(id_tipo)
);

-- INSERÇÃO DE DADOS 
-- Inserindo as 4 categorias do protótipo
INSERT INTO tipo_residuo (nome_tipo) VALUES 
('Celulares'),
('Pilhas e baterias'),
('Computadores'),
('Periféricos');

-- Inserindo pontos de coleta fictícios em Sorocaba
INSERT INTO ponto_coleta (nome_ponto, cep, endereco, horario_funcionamento) VALUES
('Ecoponto Central Sorocaba', '18035-000', 'Av. Dom Aguirre, 1000 - Centro', 'Seg a Sáb, 08h às 17h'),
('Coleta Tech Shopping', '18035-100', 'Av. Dr. Afonso Vergueiro, 500 - Centro', 'Seg a Dom, 10h às 22h'),
('EcoPonto Zona Norte', '18040-000', 'Rua da Penha, 2000 - Zona Norte', 'Seg a Sex, 08h às 16h'),
('Recicla Sorocaba - Vila Hortência', '18035-500', 'Rua Comendador Oetterer, 150 - Vila Hortência', 'Seg a Sáb, 09h às 18h');

-- Ligando os pontos aos resíduos que eles aceitam
INSERT INTO ponto_residuo (id_ponto, id_tipo) VALUES 
(1, 1), (1, 2), (1, 3), 
(2, 1), (2, 4), 
(3, 2), (3, 3), 
(4, 1), (4, 4); 

-- CONSULTAS DE TESTE (QUERIES)
-- Consulta 1: Busca Principal do Protótipo (CEP próximo + Tipo de Resíduo)
-- Simula o usuário digitando CEP 18035-000 e escolhendo "Celulares"
SELECT p.nome_ponto, p.cep, p.endereco, p.horario_funcionamento
FROM ponto_coleta p
JOIN ponto_residuo pr ON p.id_ponto = pr.id_ponto
JOIN tipo_residuo t ON pr.id_tipo = t.id_tipo
WHERE p.cep LIKE '18035%' 
  AND t.nome_tipo = 'Celulares';

-- Consulta 2: Listar todos os pontos e seus resíduos aceitos
SELECT p.nome_ponto, t.nome_tipo AS residuo_aceito
FROM ponto_coleta p
JOIN ponto_residuo pr ON p.id_ponto = pr.id_ponto
JOIN tipo_residuo t ON pr.id_tipo = t.id_tipo
ORDER BY p.nome_ponto;

-- Consulta 3: Simular busca sem resultado (Salva no histórico)
INSERT INTO busca (cep_digitado, id_tipo) VALUES ('18050-000', 1); 

-- Consulta 4: Métrica de CEPs mais buscados (para relatórios)
SELECT cep_digitado, COUNT(*) AS total_buscas
FROM busca
GROUP BY cep_digitado
ORDER BY total_buscas DESC;