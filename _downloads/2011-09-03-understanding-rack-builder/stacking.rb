class DummyA
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyA'
    str.upcase
  end
end


class DummyB
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyB'
    str.downcase
  end
end


class DummyC
  def initialize(app = nil)
    @app = app
  end

  def call(str)
    puts 'Calling DummyC'
    @app.call(str)
  end
end


# stack that will call `DummyC -> DummyA` and will result in:
#   Calling DummyC
#   Calling DummyA
#   FOOBAR
app   = DummyA.new
stack = [ proc {|app| DummyC.new app } ]
puts stack.reverse.inject(app){ |a,e| e[a] }.call("FooBar")



# stack that will call `DummyC -> DummyB` and will result in:
#   Calling DummyC
#   Calling DummyB
#   foobar
app = DummyA.new
stack = [ proc {|app| DummyC.new app }, proc {|app| DummyB.new app } ]
puts stack.reverse.inject(app){ |a,e| e[a] }.call("FooBar")


# stack that will call `DummyB` and will result in:
#   Calling DummyB
#   foobar
app = DummyA.new
stack = [ proc {|app| DummyB.new app }, proc {|app| DummyC.new app } ]
puts stack.reverse.inject(app){ |a,e| e[a] }.call("FooBar")
