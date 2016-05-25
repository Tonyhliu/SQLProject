require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db') #passing it to PlayDBConnection
    self.type_translation = true
    self.results_as_hash = true
  end
end

# -------------------------------------------

class User
  attr_accessor :fname, :lname, :id

  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end

  def self.find_by_id(id) #returns user info
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL

    return nil unless user.length > 0 #returned as an array

    User.new(user.first) #=> ['kush patel']
    #contain Question.new
    #will find users details by ID
  end

  def self.find_by_name(fname, lname) #return user info WORKING
    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    raise "#{self} not found" unless user.length > 0 #returns an array like hash object
    #=> ['kush', 'patel']
    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def followed_questions
    #one liner calling QuestionFollow method
    QuestionFollow.followers_for_user_id(@id)
  end

end

# -------------------------------------------

class Question

  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_author_id(author_id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL

    raise "#{self} not found" unless question.length > 0
    Question.new(question.first)
  end

  def self.find_by_id(id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL

    raise "#{self} not found" unless question.length > 0
    Question.new(question.first)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    User.find_by_id(@author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

end

# -------------------------------------------

class Reply

  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end


  def self.find_by_user_id(author_id) ####WORKS
    replies = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
    SELECT
      *
    FROM
      replies
    WHERE
      author_id = ?
    SQL

    raise "#{self} not found" unless replies.length > 0
    Reply.new(replies.first)
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    raise "#{self} not found" unless replies.length > 0

    replies.map do |reply|
      Reply.new(reply)
    end

    #all replies to questions at any depth
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end

  def author #how to test
    User.find_by_id(@author_id)
  end

  def question
    Question.find_by_question_id(@question_id)
  end

  def parent_reply #find @id that is the same as @parent_reply_id
    parent_reply_id = @parent_reply_id
    parent_replies = QuestionsDBConnection.instance.execute(<<-SQL, parent_reply_id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_reply_id = ?
    SQL

    raise "#{self} not found" unless parent_replies.length > 0
    Reply.new(parent_replies.first)
  end

  def child_replies #find @parent_reply_id that is the same as self.id
    id = @id
    child_replies = QuestionsDBConnection.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL

    raise "#{self} not found" unless child_replies.length > 0
    Reply.new(child_replies.first)
  end
end

# -------------------------------------------

class QuestionFollow
  def self.followers_for_question_id(question_id)
    #return an array of user objects
    follower_objects = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
    SELECT
      users.*
    FROM
      questions
    JOIN
      question_likes
    ON
      questions.id = question_likes.question_id
    JOIN
      users
    ON
      questions.author_id = users.id
    WHERE
      question_id = ?
  SQL

    raise "#{self} not found" unless follower_objects.length > 0
    follower_objects
  end

  def self.followers_for_user_id(user_id)
    #returns an array of question objects
    question_objects = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
    SELECT
      questions.*
    FROM
      users
    JOIN
      question_follows
    ON
      question_follows.user_id = users.id
    JOIN
      questions
    ON
      questions.id = question_follows.question_id
    WHERE
      user_id = ?
  SQL

    raise "#{self} not found" unless question_objects.length > 0
    question_objects.map {|question| Question.new(question)}
  end

  def self.most_followed_questions(n)
    #fetch the n most followed questions
    most_followed_question = QuestionsDBConnection.instance.execute(<<-SQL, n)
    SELECT
      questions.*, COUNT(question_follows.user_id) AS count
    FROM
      questions
    JOIN
      question_follows
    ON
      question_follows.question_id = questions.id
    ORDER BY
      count
    LIMIT ?
  SQL

    raise "#{self} not found" unless most_followed_question.length > 0
    most_followed_question.map {|question| Question.new(question)} #create objects
  end

  def most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end
end
