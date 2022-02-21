-- Exercício

-- Prepare um banco de dados para uma drogaria.
-- A drogaria vende produtos de farmácia e perfumaria, vende no balcão e faz entregas.
-- No fim do dia precisa pagar os entregadores, por isso precisa controlar quantas entregas fizeram para calcular o valor pago.

CREATE TABLE tab_cliente (
	id integer PRIMARY KEY,
	nome varchar(20) NOT NULL,
	telefone varchar(20),
	endereco varchar(100)
);

CREATE TABLE tab_cargos (
	id integer PRIMARY KEY,
	nome varchar(20) NOT NULL
);

CREATE TABLE tab_funcionario (
	id integer PRIMARY KEY,
	nome varchar(20) NOT NULL,
	idCargo integer,
	CONSTRAINT FK_Cargos_Funcionario
	FOREIGN KEY (idCargo) REFERENCES tab_cargos(id)
);

CREATE TABLE tab_produtos (
	id integer PRIMARY KEY,
	nome varchar(20) NOT NULL,
	preco money
);

CREATE TABLE tab_vendas (
	id integer CONSTRAINT PK_ID_VENDAS PRIMARY KEY,
	data_e_hora timestamp default now(),
	idCliente int,
	idFuncionario int NOT NULL,
	idProduto int NOT NULL,
	quantidade int NOT NULL,
	valor_total money NOT NULL,
	entrega boolean,
	idEntregador int,
	CONSTRAINT FK_Vendas_Cliente
	FOREIGN KEY (idCliente) REFERENCES tab_cliente(id),
	CONSTRAINT FK_Vendas_Funcionario
	FOREIGN KEY (idFuncionario) REFERENCES tab_funcionario(id),
	CONSTRAINT FK_Vendas_Produto
	FOREIGN KEY (idProduto) REFERENCES tab_produtos(id),
	CONSTRAINT FK_Vendas_Entregador
	FOREIGN KEY (idEntregador) REFERENCES tab_funcionario(id)
);

CREATE SEQUENCE seq_idCliente
INCREMENT 1
MINVALUE 1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

ALTER TABLE tab_cliente ALTER COLUMN id SET DEFAULT NEXTVAL('seq_idCliente'::regclass);

CREATE OR REPLACE FUNCTION novoCliente (varchar(20), varchar(20), varchar(20))
RETURNS void AS $$

	INSERT INTO tab_cliente (nome, telefone, endereco)
	VALUES ($1, $2, $3);

	SELECT CURRVAL('seq_idCliente');

$$
LANGUAGE 'sql';

SELECT novoCliente ('Bruno Henrique', '21 99894-0101', 'Rua do Patamar, 46');
SELECT novoCliente ('Gabriel Barbosa', '21 99958-7235', 'Rua Dantas, 554');
SELECT novoCliente ('Arrascaeta', '21 98732-2121', 'Rua das Árvores, 20');
SELECT novoCliente ('Jorge Jesus', '21 99273-3919', 'Rua das Artes, 115');
SELECT novoCliente ('Arthur Antunes', '21 98832-0186', 'Rua do Mundo, 10');			
SELECT novoCliente ('Paulo Sousa', '21 99990-2022', 'Rua dos Românticos, 22');

SELECT * FROM tab_cliente;

----------

CREATE SEQUENCE seq_idCargos
INCREMENT 1
MINVALUE 1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

ALTER TABLE tab_cargos ALTER COLUMN id SET DEFAULT NEXTVAL('seq_idCargos'::regclass);

CREATE OR REPLACE FUNCTION insCargos (varchar(20))
RETURNS void AS $$

	INSERT INTO tab_cargos (nome)
	VALUES ($1);

	SELECT CURRVAL('seq_idCargos');

$$
LANGUAGE 'sql';

SELECT insCargos ('Gerente');
SELECT insCargos ('Supervisor');
SELECT insCargos ('Balconista');
SELECT insCargos ('Caixa');
SELECT insCargos ('Entregador');

SELECT * FROM tab_cargos;

----------

CREATE SEQUENCE seq_idFuncionario
INCREMENT 1
MINVALUE 1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

ALTER TABLE tab_funcionario ALTER COLUMN id SET DEFAULT NEXTVAL('seq_idFuncionario'::regclass);

CREATE OR REPLACE FUNCTION novoFuncionario (varchar(20), varchar(20))
RETURNS void AS $$

	INSERT INTO tab_funcionario (nome, idCargo)
	VALUES ($1, (SELECT id FROM tab_cargos WHERE nome LIKE '%' || $2 || '%'));

	SELECT CURRVAL('seq_idFuncionario');

$$
LANGUAGE 'sql';

SELECT novoFuncionario ('Manoel', 'Balconista');
SELECT novoFuncionario ('Chico', 'Entregador');
SELECT novoFuncionario ('Maria', 'Supervisor');
SELECT novoFuncionario ('João', 'Caixa');
SELECT novoFuncionario ('José', 'Gerente');
SELECT novoFuncionario ('Claudia', 'Balconista');

SELECT * FROM tab_funcionario;

----------

CREATE SEQUENCE seq_idProdutos
INCREMENT 1
MINVALUE 1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

ALTER TABLE tab_produtos ALTER COLUMN id SET DEFAULT NEXTVAL('seq_idProdutos'::regclass);

CREATE OR REPLACE FUNCTION insProdutos (varchar(20), money)
RETURNS void AS $$

	INSERT INTO tab_produtos (nome, preco)
	VALUES ($1, $2);

	SELECT CURRVAL('seq_idProdutos');

$$
LANGUAGE 'sql';

SELECT insProdutos ('Dipirona'::varchar(20), 10::money);
SELECT insProdutos ('Teste Rápido PCR'::varchar(20), 120::money);
SELECT insProdutos ('Xarope'::varchar(20), 22::money);
SELECT insProdutos ('Benegripe'::varchar(20), 6.5::money);
SELECT insProdutos ('Perfume Nacional 50ml'::varchar(20), 50::money);
SELECT insProdutos ('Perfume Importado 50ml'::varchar(20), 350::money);
SELECT insProdutos ('Spray de Própolis'::varchar(20), 15::money);
SELECT insProdutos ('Desodorante'::varchar(20), 16::money);

SELECT * FROM tab_produtos;

----------

CREATE SEQUENCE seq_idVendas
INCREMENT 1
MINVALUE 1
MAXVALUE 9223372036854775807
START 1
CACHE 1;

ALTER TABLE tab_vendas ALTER COLUMN id SET DEFAULT NEXTVAL('seq_idVendas'::regclass);

CREATE OR REPLACE FUNCTION totalVenda (p_idProduto varchar(20), p_quantidade integer)
RETURNS money AS $$

BEGIN

	RETURN (SELECT preco FROM tab_produtos WHERE tab_produtos.nome LIKE p_idProduto) * p_quantidade;

END;

$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION novaVenda (varchar(20), varchar(20), varchar(20), integer, boolean, varchar(20))
RETURNS void AS $$

BEGIN

	INSERT INTO tab_vendas (idCliente, idFuncionario, idProduto, quantidade, valor_total, entrega, idEntregador)

	VALUES (
	 		(SELECT id FROM tab_cliente WHERE nome LIKE '%' || $1 || '%'),
	  		(SELECT id FROM tab_funcionario WHERE nome LIKE '%' || $2 || '%'),
	   		(SELECT id FROM tab_produtos WHERE nome LIKE '%' || $3 || '%'),
	    	$4::integer,
	    	(SELECT totalVenda($3::varchar(20), $4::integer)),
			$5::boolean,
			(SELECT id FROM tab_funcionario WHERE nome LIKE '%' || $6 || '%'))
	;
	
END;	

$$
LANGUAGE 'plpgsql';

SELECT novaVenda ('Arthur%', 'Manoel%', 'Spray%', 3, false, NULL);
SELECT novaVenda ('Gabriel%', 'Manoel%', 'Teste%', 4, true, 'Chico');
SELECT novaVenda ('Paulo%', 'Manoel%', 'Xarope%', 2, false, NULL);
SELECT novaVenda ('Jorge%', 'Manoel%', 'Perfume Imp%', 2, true, 'Chico');
SELECT novaVenda ('Bruno%', 'Manoel%', 'Deso%', 2, true, 'Chico');
SELECT novaVenda ('Arras%', 'Manoel%', 'Dipi%', 1, true, 'Chico');

SELECT * FROM tab_vendas;

----------

CREATE OR REPLACE FUNCTION vendaByEntregador(integer)
RETURNS bigint AS $$

	SELECT COUNT(*) FROM tab_vendas WHERE idEntregador = $1 AND data_e_hora::date = CURRENT_DATE;

$$
LANGUAGE 'sql';

SELECT vendaByEntregador(2::integer);