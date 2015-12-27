require 'singleton'
require "red_black_tree/version"

class RedBlackTree
  class Node
    attr_accessor :color, :key, :value, :left, :right

    RED = :red
    BLACK = :black

    def initialize(color, key, value)
      @color = color
      @key = key
      @value = value
      @left = NilNode.instance
      @right = NilNode.instance
    end

    def red?
      @color == RED
    end

    def black?
      @color == BLACK
    end

    def nil?
      false
    end
  end

  class NilNode < Node
    include Singleton

    def initialize
      @left  = self
      @right = self
    end

    def nil?
      true
    end
  end

  def initialize
    @root = NilNode.instance
    @rebalance = false
  end

  def [](key)
    node = @root
    while node
      case key <=> node.key
      when -1
        node = node.left
      when 0
        return node.value
      when 1
        node = node.right
      end
    end
    nil
  end

  def []=(key, value)
    @root = insert_node(@root, key, value)
    @root.color = Node::BLACK
  end

  def delete(key)
    @root = delete_node(@root, key)
    @root.color = Node::BLACK unless @root.nil?
  end

  private

  def insert_node(node, key, value)
    return Node.new(Node::RED, key, value) if node.nil?

    case key <=> node.key
    when -1
      node.left = insert_node(node.left, key, value)
      balance(node)
    when 0
      node.value = value
      node
    when 1
      node.right = insert_node(node.right, key, value)
      balance(node)
    else
      raise TypeError, "cannot compare #{key} and #{node.key} with <=>"
    end
  end

  def balance(node)
    return node if node.red?

    case
    when node.left.red? && node.left.left.red?
      node = rotate_right(node)
      node.left.color = Node::BLACK
    when node.left.red? && node.left.right.red?
      node.left = rotate_left(node.left)
      node = rotate_right(node)
      node.left.color = Node::BLACK
    when node.right.red? && node.right.right.red?
      node = rotate_left(node)
      node.right.color = Node::BLACK
    when node.right.red? && node.right.left.red?
      node.right = rotate_right(node.right)
      node = rotate_left(node)
      node.right.color = Node::BLACK
    end

    node
  end

  def rotate_left(node)
    rnode = node.right
    node.right = rnode.left
    rnode.left = node
    rnode
  end

  def rotate_right(node)
    lnode = node.left
    node.left = lnode.right
    lnode.right = node
    lnode
  end

  def delete_node(node, key)
    return node if node.nil?

    case key <=> node.key
    when -1
      node.left = delete_node(node.left, key)
      balance_left(node)
    when 0
      if !node.left.nil?
        max_node = maximum(node.left)
        node.key = max_node.key
        node.value = max_node.value
        node.left = delete_node(node.left, node.key)
        balance_left(node)
      elsif !node.right.nil?
        node.right
      else
        @rebalance = true if node.black?
        NilNode.instance
      end
    when 1
      node.right = delete_node(node.right, key)
      balance_right(node)
    end
  end

  def maximum(node)
    node.right.nil? ? node : maximum(node.right)
  end

  def balance_left(node)
    return node unless @rebalance

    case
    when node.right.black? && node.right.left.red?
      @rebalance = false
      color = node.color
      node.right = rotate_right(node.right)
      node = rotate_left(node)
      node.left.color = Node::BLACK
      node.color = color
      node
    when node.right.black? && node.right.right.red?
      @rebalance = false
      color = node.color
      node = rotate_left(node)
      node.right.color = Node::BLACK
      node.color = color
      node
    when node.right.black?
      @rebalance = false if node.red?
      node.color = Node::BLACK
      node.right.color = Node::RED
      node
    when node.right.red?
      node = rotate_left(node)
      node.color = Node::BLACK
      node.left.color = Node::RED
      balance_left(node.left)
    else
      node
    end
  end

  def balance_right(node)
    return node unless @rebalance

    case
    when node.left.black? && node.left.right.red?
      @rebalance = false
      color = node.color
      node.left = rotate_left(node.left)
      node = rotate_right(node)
      node.right.color = Node::BLACK
      node.color = color
      node
    when node.left.black? && node.left.left.red?
      @rebalance = false
      color = node.color
      node = rotate_right(node)
      node.left.color = Node::BLACK
      node.color = color
      node
    when node.left.black?
      @rebalance = false if node.red?
      node.color = Node::BLACK
      node.left.color = Node::RED
      node
    when node.left.red?
      node = rotate_right(node)
      node.color = Node::BLACK
      node.right.color = Node::RED
      balance_left(node.right)
    else
      node
    end
  end

  module Debug
    def check_tree(node = @root)
      return 0 if node.nil?

      if node.red? && (node.left.red? || node.right.red?)
        puts dump_tree(node)
        raise 'red/red node failed.'
      end

      a = check_tree(node.left)
      b = check_tree(node.right)
      if a != b
        puts dump_tree(node)
        raise "black height unbalanced: #{a} #{b}"
      end

      a += 1 if node.black?
      a
    end

    def dump_tree(node = @root, head = "", bar = "")
      str = ""
      margin = "      "
      unless node.nil?
        str += dump_tree(node.right, head + margin, "/")
        color = node.color == Node::RED ? "R" : "B"
        color += ":" + node.key.to_s
        str += head + bar + color + "\n"
        str += dump_tree(node.left, head + margin, "\\")
      end
      str
    end
  end
  include Debug
end
