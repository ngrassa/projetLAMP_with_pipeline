CREATE TABLE IF NOT EXISTS articles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(100),
    contenu TEXT
);

INSERT INTO articles (titre, contenu) VALUES
('Article 1', 'Cloud Computing'),
('Article 2', 'DevSecOps'),
('Article 3', 'Gitops');
