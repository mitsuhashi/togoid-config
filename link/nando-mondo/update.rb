#!/usr/bin/env ruby
require 'optparse'
require 'open3'

params = ARGV.getopts("l:e:h", "limit:", "endpoint:", "help")

help = <<"EOS"
  Usage: update.rb [options]
    -l <number of limit | all>
    -e <endpoint uri>
    -h help
        --limit=<number of limit | all>
        --endpoint=<endpoint uri>

    example: > ./update.rb -l all -e http://integbio.jp/rdf/sparql
EOS

if params["h"] || params["help"]
  STDERR.print "#{help}"
  exit
end

if params["endpoint"]
  ENDPOINT = params["endpoint"]
elsif params["e"]
  ENDPOINT = params["e"]
else
  ENDPOINT = 'https://integbio.jp/rdf/sparql'
end

if params["limit"] == "all" || params["l"] == "all"
  LIMIT = ""
elsif params["limit"]
  LIMIT = "LIMIT #{params["limit"]}"
elsif params["l"]
  LIMIT = "LIMIT #{params["l"]}"
else
  LIMIT = "LIMIT 2"
end

STDERR.print "ENDPOINT #{ENDPOINT}\n" if $DEBUG
STDERR.print "#{LIMIT}\n"             if $DEBUG

sparql = <<"EOS"
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT DISTINCT ?nando_id ?mondo_id
FROM <http://nanbyodata.jp/ontology/nando>
WHERE {
  ?nando a owl:Class ;
         dcterms:identifier ?nando_id ;
         skos:closeMatch ?mondo .
  FILTER(REGEX(?mondo, "MONDO"))
  BIND(STRAFTER(str(?mondo), "obo/") AS ?mondo_id)
} ORDER BY ?nando_id
#{LIMIT}
EOS

result, status = Open3.capture2("curl -H 'Accept: text/tab-separated-values' --data-urlencode 'query=#{sparql.gsub("\n", " ")}' #{ENDPOINT}| tail -n +2 | tr -d '\"'")

STDERR.print "#{status}\n" if $DEBUG

puts result

