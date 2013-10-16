RSpec.configure do |c|
  
  c.treat_symbols_as_metadata_keys_with_true_values = true

  c.around(:each, :capture) do |example|
    capture(:stdout) { example.call }
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
    ensure
      eval "$#{stream} = #{stream.upcase}"
    end
  end

  def expect_output(*strings)
    strings.each do |string|
      expect($stdout.string).to include(string)
    end
  end
end