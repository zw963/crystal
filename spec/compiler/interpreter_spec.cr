require "./interpreter/*"

describe "run interpreter" do
  it "should running interpreter sucessful on linux" do
    {% if flag?(:linux) %}
      status_code = system("./bin/crystal i <<< 'puts 1'")

      status_code.should be_true
    {% end %}
  end
end
