require 'net/http'
require 'uri'
require 'json'
require 'rdf'
require 'rdf/turtle'
require 'uuid'
include RDF

output = "/Volumes/orenostorage/PRIDE/RDF"
rdf    = ""

def get_jsons(uri)
  return get_json(uri)["list"]
end

def get_json(uri)
  return JSON.parse(get_uri(uri))
end

def get_uri(uri)
  return Net::HTTP.get(URI.parse(uri))
end

def uri_p(url)
  return "<" + url + ">"
end

def literal_p(word)
  return "\"#{word}\""
end

def generate_rdf(uri, i, f)
  i.each do |key, value|
    if value.kind_of?(Float) || value && value.to_s.size > 0
      if value.kind_of?(Array)
        value.each do |v|
          if v.kind_of?(Hash)
            bnode = RDF::Node.uuid.to_s.delete("-")
            f.puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{bnode} ."
            f.puts "#{bnode} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/#{key.sub(/s$/, "").capitalize}> ."
    
            v.each do |k, v2|
              f.puts "#{bnode} <http://www.ebi.ac.uk/pride/rdf/#{k}> #{literal_p(v2)} ."
            end
        
          else
            f.puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{literal_p(v)} ."
          end
        end
      elsif value.kind_of?(Hash)
        bnode = RDF::Node.uuid.to_s.delete("-")
        f.puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{bnode} ."
        f.puts "#{bnode} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/#{key.sub(/s$/, "").capitalize}> ."
    
        value.each do |k, v|
          f.puts "#{bnode} <http://www.ebi.ac.uk/pride/rdf/#{k}> #{literal_p(v)} ."
        end
      else
        f.puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{literal_p(value)} ."
      end
    end
  end
end

base_uri        = "http://www.ebi.ac.uk/pride/archive/projects/"
identifiers_uri = "http://identifiers.org/"

#########################################################
#  define PREFIX
#########################################################
pride = RDF::Vocabulary.new("http://www.ebi.ac.uk/pride/rdf/")
up    = RDF::Vocabulary.new("http://purl.uniprot.org/core/")
rdf   = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")

pride = "http://www.ebi.ac.uk/pride/rdf/"
rdf   = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

#prefix = "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
#@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
#@prefix pride: <http://www.ebi.ac.uk/pride/rdf/> ."

#puts prefix


#########################################################
#  project accession numbers in PRIDE
#########################################################
project_number = get_uri("http://wwwdev.ebi.ac.uk/pride/ws/archive/project/count")
projects       = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/project/list?show=#{project_number}")


#########################################################
#  resume
#########################################################
=begin
accessions = Array.new
projects.each do |k|
  accessions << k["accession"]
end
skip = accessions.index("PRD000066")
projects.shift(skip)
=end


projects.each do |project|
  #########################################################
  #  retrieving project metadata
  #########################################################
  #pid = "PXD000605"
  pid = project["accession"]

  unless pid == "PXT000186" || pid == "PXT000177" || pid == 'PRD000721' || pid == 'PRD000066'
    f = File.open("#{output}/#{pid}.nt", "w")

    project_json = get_json("http://wwwdev.ebi.ac.uk/pride/ws/archive/project/#{pid}")
    #project_json = JSON.parse(File.open("sample_data/project.json").read)
    project_uri  = base_uri + pid

    puts project_uri

    f.puts "#{uri_p(project_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/PrideProject> ."

    generate_rdf(project_uri, project_json, f)


    #########################################################
    #  retrieving file information
    #########################################################
    #files = get_jsons("http://wwwdev.ebi.ac.uk:80/pride/ws/archive/file/list/project/#{pid}")
    #files.each do |file|
    #  file[downloadLink]
    #end

    #########################################################
    #  retrieving project assays
    #########################################################
    num_assays = project["numAssays"]
    puts num_assays
    
    assays = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/assay/list/project/#{pid}?show=#{num_assays}")
    #assays = JSON.parse(File.open("sample_data/assays.json").read)["list"]

    assays.each do |assay|
      assay_uri = base_uri + pid + "/assays/" + assay["assayAccession"]
  
      puts assay_uri
  
      f.puts "#{uri_p(project_uri)} #{uri_p(pride + "has_assay")} #{uri_p(assay_uri)} ."
      f.puts "#{uri_p(assay_uri)} #{uri_p(rdf + "type")} <http://www.ebi.ac.uk/pride/rdf/Assay> ."

      generate_rdf(assay_uri, assay, f)

  
      #########################################################
      #  retrieving proteins in assay
      #########################################################
      puts assay["proteinCount"]
      if assay["proteinCount"] == 0
        assay["proteinCount"] = 1
      end
      proteins = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/protein/list/assay/#{assay["assayAccession"]}?show=#{assay["proteinCount"]}")
      #proteins = JSON.parse(File.open("sample_data/proteins.json").read)["list"]
      
      puts proteins.size
      proteins.each do |protein|
        protein_uri = [assay_uri, protein["accession"]].join("/")
    
        #puts protein_uri
    
        f.puts "#{uri_p(assay_uri)} <http://www.ebi.ac.uk/pride/rdf/has_protein> #{uri_p(protein_uri)} ."
        f.puts "#{uri_p(protein_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/Protein> ."
    
        generate_rdf(protein_uri, protein, f)
        #break
      end

  
      #########################################################
      #  retrieving peptides in assay
      #########################################################
      peptides = Array.new
      peptide_count = 0
      page = 0
      
      puts assay["peptideCount"]
      if assay["peptideCount"] == 0
        assay["peptideCount"] = 1
      end
      if assay["peptideCount"].to_i > 50000
        while assay["peptideCount"].to_i > peptide_count
          peptides += get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/peptide/list/assay/#{assay["assayAccession"]}?show=50000&page=#{page}")
          peptide_count += 50000
          page += 1
          puts peptide_count
        end
      else
        peptides = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/peptide/list/assay/#{assay["assayAccession"]}?show=#{assay["peptideCount"]}")
        #peptides = JSON.parse(File.open("sample_data/peptides.json").read)["list"]
      end
      
      puts peptides.size
      peptides.each do |peptide|
        peptide_uri = [assay_uri, peptide["id"]].join("/")
    
        #puts peptide_uri
    
        f.puts "#{uri_p(assay_uri)} <http://www.ebi.ac.uk/pride/rdf/detected_peptide> #{uri_p(peptide_uri)} ."
        f.puts "#{uri_p(peptide_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/Peptide> ."
    
        generate_rdf(peptide_uri, peptide, f)
        #break
      end
      #break
    end
    f.close
  end
  #break
end
