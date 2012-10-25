require "rubygems"
require "bundler/setup"
require "shellwords"
require "yaml"


Bundler.require


def say_what? message
  print message
  STDIN.gets.chomp
end


def sluggize str
  str.downcase.gsub(/[^a-z0-9]+/, '-');
end


desc "Generate blog files"
task :generate do
  Jekyll::Site.new(Jekyll.configuration({
    "source"      => ".",
    "destination" => "_site"
  })).process
end


desc "Generate and publish blog to gh-pages"
task :publish => [:generate] do
  Dir.mktmpdir do |tmp|
    cp_r "_site/.", tmp
    Dir.chdir tmp
    system "git init"
    system "git add ."
    message = "Site updated at #{Time.now.utc}"
    system "git commit -m #{message.shellescape}"
    system "git remote add origin git@github.com:ixti/ixti.github.com.git"
    system "git push origin master --force"
  end
end


$editor = ENV['EDITOR'] || ""


desc "Create a new post"
task :new do
  title     = say_what?('Title: ')
  filename  = "_posts/#{Time.now.strftime('%Y-%m-%d')}-#{sluggize title}.md"

  if File.exist? post_path
    puts "I can't create the post: \e[33m#{filename}\e[0m"
    puts "  \e[31m- Path already exists.\e[0m"
    exit 1
  end

  File.open(filename, "w") do |post|
    post.puts "---"
    post.puts "layout:    post"
    post.puts "category:  ~"
    post.puts "tags:      []"
    post.puts "title:     #{title}"
    post.puts "---"
    post.puts ""
    post.puts "Once upon a time..."
  end


  if !$editor.empty? && 'Y' == say_what?('Edit? ').upcase[0]
    system "#{$editor} #{filename}"
  end

  puts "a new post was created for you at:"
  puts "  \e[32m#{post_path}\e[0m"
end

if !$editor.empty?
  desc "Edit post"
  task :edit do
    posts     = Dir["_posts/*.md"].sort_by{ |f| File.basename f }.reverse!
    per_page  = 9;

    begin
      page = posts.slice!(0, per_page)
      page.each_with_index {|f, i| puts "%2d %s" % [i + 1, File.basename(f)]}

      puts "Enter number to edit, or nothing to skip to next page"
      id = say_what? "> "
    end while posts.count > 0 && id.empty?

    case
      when "Q" == id.upcase
        exit 0
      when id.empty?
        puts "no more posts"
        exit 0
      else
        id = id.to_i
        unless 0 < id && id < per_page
          puts "wrong post number"
          exit 1
        end
    end

    system "#{$editor} #{page[id - 1]}"
  end
end
