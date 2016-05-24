


CREATE TABLE users (

  id INTEGER PRIMARY KEY,
  fname VARCHAR NOT NULL,
  lname VARCHAR NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Kush', 'Patel'),
  ('Sam', 'TA'),
  ('Gage', 'TA2'),
  ('Coop', 'Tony');


CREATE TABLE questions (

  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('How''s everyone doing', 'tired', (SELECT id FROM users WHERE fname = 'Gage' AND lname = 'TA2')),
  ('How''s lunch', 'great', (SELECT id FROM users WHERE fname = 'Sam' AND lname = 'TA'));

CREATE TABLE question_follows ( /* joins table */
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Gage' AND lname = 'TA2'),
  (SELECT id FROM questions WHERE title LIKE '%doing')),
  ((SELECT id FROM users WHERE fname = 'Sam' AND lname = 'TA'),
  (SELECT id FROM questions WHERE title LIKE '%lunch'));

CREATE TABLE replies (

  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  parent_reply INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_reply) REFERENCES replies(id)

);

INSERT INTO
  replies (body, user_id, question_id, parent_reply)
VALUES
  ('hi hi hi',
  (SELECT id FROM users WHERE fname = 'Gage'),
  (SELECT id FROM questions WHERE body = 'tired'),
  NULL
);
/* self referential insert */
INSERT INTO
  replies (body, user_id, question_id, parent_reply)
VALUES
  ('hello hello hello',
  (SELECT id FROM users WHERE fname = 'Sam'),
  (SELECT id FROM questions WHERE body = 'tired'),
  (SELECT id FROM replies WHERE lname = 'TA2' AND body = 'hi hi hi')
);



CREATE TABLE question_likes(
  id INTEGER PRIMARY KEY,
  liked BOOLEAN NOT NULL DEFAULT '0',
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id)
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  question_likes (liked, user_id, question_id)
VALUES
  (0, 1, 1);
INSERT INTO
  question_likes (liked, user_id, question_id)
VALUES
  (0, 1, 2);
