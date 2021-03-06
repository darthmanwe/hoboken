module Hoboken
  module AddOns
    class Sprockets < ::Hoboken::Group
      def create_assets_folder
        empty_directory("assets")
        FileUtils.cp("public/css/styles.css", "assets/styles.css")
        FileUtils.cp("public/js/app.js", "assets/app.js")
      end

      def add_gems
        gem "sprockets", version: "2.10.0", group: :assets
        gem "uglifier", version: "2.1.1", group: :assets
        gem "yui-compressor", version: "0.9.6", group: :assets
      end

      def copy_sprockets_helpers
        copy_file("hoboken/templates/sprockets.rake", "tasks/sprockets.rake")
        copy_file("hoboken/templates/sprockets_chain.rb", "middleware/sprockets_chain.rb")
        copy_file("hoboken/templates/sprockets_helper.rb", "helpers/sprockets.rb")
      end

      def update_app
        insert_into_file("app.rb", after: /configure :development do\n/) do
<<CODE
      require File.expand_path('middleware/sprockets_chain', settings.root)
      use Middleware::SprocketsChain, %r{/assets} do |env|
        %w(assets vendor).each do |f|
          env.append_path File.expand_path("../\#{f}", __FILE__)
        end
      end

CODE
        end

        insert_into_file("app.rb", after: /set :root, File.dirname\(__FILE__\)\n/) do
          "    helpers Helpers::Sprockets"
        end

        gsub_file("app.rb", /require "sinatra\/reloader" if development\?/) do
<<CODE
if development?
  require "sinatra/reloader"

  require File.expand_path('middleware/sprockets_chain', settings.root)
  use Middleware::SprocketsChain, %r{/assets} do |env|
    %w(assets vendor).each do |f|
      env.append_path File.expand_path("../\#{f}", __FILE__)
    end
  end
end

helpers Helpers::Sprockets
CODE
        end
      end

      def adjust_link_tags
        insert_into_file("views/layout.erb", before: /<\/head>/) do
<<HTML
  <%= stylesheet_tag :styles %>

  <%= javascript_tag :app %>
HTML
        end

        gsub_file("views/layout.erb", /<link rel="stylesheet" type="text\/css" href="css\/styles.css">/, "")
        gsub_file("views/layout.erb", /<script type="text\/javascript" src="js\/app.js"><\/script>/, "")
      end

      def directions
        text = <<TEXT

Run `bundle install` to get the sprockets gem and its
dependencies.

Running the server in development mode will serve css
and js files from /assets. In order to serve assets in
production, you must run `rake assets:precompile`. Read
the important note below before running this rake task.
TEXT

        important = <<TEXT

Important Note:
Any css or js files from the /public folder have been copied
to /assets, the original files remain intact in /public, but
will be replaced the first time you run `rake assets:precompile`.
You may want to backup those files if they are not under source
control before running the Rake command.
TEXT

        say text
        say important, :red
      end
    end
  end
end
