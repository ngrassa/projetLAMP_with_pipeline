CREATE TABLE IF NOT EXISTS articles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(100),
    contenu TEXT
);

INSERT INTO articles (titre, contenu) VALUES
('Article 1', 'Contenu du premier article'),
('Article 2', 'Contenu du deuxième article'),
('Article 3', 'Contenu du troisième article');
