# encoding: UTF-8

require 'rubygems'
require 'uri'
#require 'typhoeus'
require 'cgi'
require 'net/http'

base_url = "http://www.filmaffinity.com/es/search.php?stext="
base_film_url = "http://www.filmaffinity.com/es/film"
fails = 0

def findId(res)
  loc = res['Location']
  if loc.include? "es/film"
    puts res['Location']
    bid = res['Location'].split("m")
    pid = bid[1].split(".")
    id = pid[0]
  else
    id=0
  end
  puts id
  return id
end


def getFilmInfo(number, title, id, resf)
  n=1
  bodyf = resf.body.force_encoding('UTF-8')
  bf = bodyf.split('class="movie-info">')
  if bf[1].include? 'class="akas"'
    n=n+1
  end
  movie_info = bf[1].split("</dd>")
  lyear = movie_info[n].split('"datePublished">')
  year = lyear[1]
  puts year.nil?
  ltime = movie_info[n+1].split("<dd>")
  time = ltime[1]
  puts time.nil?
  lcountry = movie_info[n+2].split("&nbsp;")
  country = lcountry[1]
  puts country.nil?
  filminf = number + "."+title+" id: "+id+"| año: "+year+"| duración: "+time+"| país: "+country
  return filminf
end

pelis = File.open('/home/rixhack/PelisPendientes','rb:UTF-8')
#pelis = File.open('./PelisPendientesTest','r:UTF-8')
pelisx = File.open('PelisPendientesX','wb');
while line = pelis.gets
  puts line
  l = line.split('.')
  number = l[0]
  title = l[1]
  titleESC= CGI.escape(title)
  uri=URI.parse(URI.encode(base_url+titleESC," "))
  puts uri
  req = Net::HTTP::Get.new(uri.to_s)
  res = Net::HTTP.start(uri.host, uri.port) {|http| http.request(req)}
  body = res.body
  b = body.split("/es/film")
  if !b.empty?
    b2 = b[1].split(".html")
    id = b2[0]
  else
    id = findId(res)
  end
  if id!=0
    film_uri=URI.parse(base_film_url+id+".html")
    puts film_uri
    reqf = Net::HTTP::Get.new(film_uri.to_s)
    resf = Net::HTTP.start(film_uri.host, 80, :open_timeout => 6)  {|http| 
                                                  http.request(reqf)}  
    filminf = getFilmInfo(number, title, id, resf)
    pelisx.puts filminf
  else
    fails=fails+1
  end
  #pelisx.close
end
puts "Fails: "+fails.to_s
pelisx.close
  
  
  
