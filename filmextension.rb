# encoding: UTF-8

require 'rubygems'
require 'uri'
#require 'typhoeus'
require 'cgi'
require 'net/http'
require 'sqlite3'

base_url = "http://www.filmaffinity.com/es/search.php?stext="
base_film_url = "http://www.filmaffinity.com/es/film"
fails = 0
db = SQLite3::Database.open "PelisPendientes.db"
db.execute "DROP TABLE Films"
db.execute "CREATE TABLE Films(Id INTEGER PRIMARY KEY, Number INTEGER, Title TEXT, Year INTEGER, RunningTime INTEGER, Country TEXT, Rating REAL)" 

def findId(res)
  loc = res['Location']
  if loc.include? "es/film"
    #puts res['Location']
    bid = res['Location'].split("m")
    pid = bid[1].split(".")
    id = pid[0]
  else
    id=0
  end
  #puts id
  return id
end


def getFilmInfo(number, title, id, resf, db)
  n=1
  bodyf = resf.body.force_encoding('UTF-8')
  bf = bodyf.split('class="movie-info">')
  if bf[1].include? 'class="akas"'
    n=n+1
  end
  movie_info = bf[1].split("</dd>")
  lyear = movie_info[n].split('"datePublished">')
  year = lyear[1]
  ltime = movie_info[n+1].split("<dd>")
  time = ltime[1]
  lcountry = movie_info[n+2].split("&nbsp;")
  country = lcountry[1]
  lrating = bf[0].split('itemprop="ratingValue">')
  if not lrating[1].nil?
    lrating2 = lrating[1].split("</div>")
    rating = lrating2[0]
  else
    rating = "0.0"
  end
  #filminf = number + "."+title+" id: "+id+"| año: "+year+"| duración: "+time+"| país: "+country+"| puntuación: "+rating
  insertDB(id, number, title, year, time, country, rating, db)
  #return filminf
end


def insertDB(id, number, title, year, time, country, rating, db)
  begin
    stm = db.prepare "INSERT INTO Films VALUES(?, ?, ?, ?, ?, ?, ?)"
    stm.bind_param 1, id.to_i
    stm.bind_param 2, number.to_i
    stm.bind_param 3, title
    stm.bind_param 4, year.to_i
    stm.bind_param 5, time.to_i
    stm.bind_param 6, country
    stm.bind_param 7, rating.gsub(",",".").to_f
    stm.execute
  rescue SQLite3::Exception => e
    puts "Exception occured"
    puts e
  end
end

pelis = File.open('/home/rixhack/PelisPendientes','rb:UTF-8')
#pelis = File.open('./PelisPendientesTest','rb:UTF-8')
#pelisx = File.open('PelisPendientesX','wb'); 
while line = pelis.gets
  puts line
  l = line.split('.')
  number = l[0]
  title = l[1]
  titleESC= CGI.escape(title)
  uri=URI.parse(URI.encode(base_url+titleESC," "))
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
    reqf = Net::HTTP::Get.new(film_uri.to_s)
    resf = Net::HTTP.start(film_uri.host, 80, :open_timeout => 6)  {|http| 
                                                  http.request(reqf)}  
    getFilmInfo(number, title, id, resf, db)
    #pelisx.puts filminf
  else
    fails=fails+1
  end
end
puts "Fails: "+fails.to_s
#pelisx.close
