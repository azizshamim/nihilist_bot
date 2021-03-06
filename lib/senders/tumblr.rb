require 'net/http'
require 'uri'
$:.unshift File.join(File.dirname(__FILE__), %w[.. htmlentities lib])
require 'htmlentities'

# post to tumblr.com -- see http://www.tumblr.com/api/
class BotSender::Tumblr < BotSender
  def validate(args = {})
    [ :post_url, :site_url, :email, :password ].each {|arg| raise ArgumentError, ":#{arg} is required" unless args[arg] }
    @post_url = args[:post_url]
    @email    = args[:email]
    @password = args[:password]
    @site_url = args[:site_url]
    @group    = args[:group]
  end

  def do_quote(args = {})
    source = args[:source] || ''
    source = %Q[<a href="#{args[:url]}">#{source}</a>] if args[:url]
    data   = { 
      :type     => 'quote', 
      :quote    => HTMLEntities.new.encode(args[:quote] || ''), 
      :source   => source
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end
  
  def do_text(args = {})
    data = { 
      :type     => 'regular', 
      :title    => (args[:title] || ''),
      :body     => (args[:body] || '')
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end
  
  alias_method :do_fact, :do_text
  alias_method :do_true_or_false, :do_text
  alias_method :do_definition, :do_text

  def do_image(args = {})
    caption = args[:source] ? %Q[#{args[:caption] || ''} <a href="#{args[:source]}">zoom</a>] : ''
    data    = { 
      :type           => 'photo',
      :source         => (args[:source] || ''),
      :caption        => caption 
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end

  def do_chat(args = {})
    data = { 
      :type           => 'conversation', 
      :title          => (args[:title] || ''),
      :conversation   => (args[:body] || '')
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end
  
  def do_video(args = {})
    data = { 
      :type           => 'video', 
      :caption        => (args[:caption] || ''),
      :embed          => (args[:embed] || '')
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end

  def do_link(args = {})
    data = { 
      :type           => 'link', 
      :url            => (args[:url] || ''),
      :name           => (args[:name] || ''),
      :description    => (args[:description] || '')
    }.merge(credentials)
    result = Net::HTTP.post_form(URI.parse(@post_url), data)
    handle_response(result, args)
  end
  
  def handle_response(response, metadata)
    return nil unless response
    type_string = metadata[:type].to_s.gsub(/_/, ' ')
    case response
      when Net::HTTPSuccess
        "created #{type_string} for #{metadata[:poster]} at #{@site_url.sub(%r{/$}, '')}/post/#{response.body.to_s}"
      else
        "encountered error: [#{response.error!}] when trying to post #{type_string} for #{metadata[:poster]}"
    end
  end

  private

  def credentials
    creds = {
      :email    => @email,
      :password => @password
    }
    creds[:group] = @group if @group
    creds
  end
end
