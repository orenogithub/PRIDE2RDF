require 'net/http'
require 'uri'
require 'json'
require 'rdf'
require 'rdf/turtle'
include RDF

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

def generate_rdf(uri, i)
  i.each do |key, value|
    if value.kind_of?(Float) || value && value.size > 0
      if value.kind_of?(Array)
        value.each do |v|
          if v.kind_of?(Hash)
            bnode = RDF::Node.uuid.to_s.delete("-")
            puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{bnode} ."
            puts "#{bnode} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/#{key.sub(/s$/, "").capitalize}> ."
    
            v.each do |k, v2|
              puts "#{bnode} <http://www.ebi.ac.uk/pride/rdf/#{k}> #{literal_p(v2)} ."
            end
        
          else
            puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{literal_p(v)} ."
          end
        end
      elsif value.kind_of?(Hash)
        bnode = RDF::Node.uuid.to_s.delete("-")
        puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{bnode} ."
        puts "#{bnode} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/#{key.sub(/s$/, "").capitalize}> ."
    
        value.each do |k, v|
          puts "#{bnode} <http://www.ebi.ac.uk/pride/rdf/#{k}> #{literal_p(v)} ."
        end
      else
        puts "#{uri_p(uri)} <http://www.ebi.ac.uk/pride/rdf/#{key}> #{literal_p(value)} ."
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
#  retrieving project metadata
#########################################################
pid = "PXD001328"

project     = get_json("http://wwwdev.ebi.ac.uk/pride/ws/archive/project/#{pid}")
#project     = JSON.parse(File.open("sample_data/project.json").read)
project_uri = base_uri + pid
puts "#{uri_p(project_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/PrideProject> ."

generate_rdf(project_uri, project)


#########################################################
#  retrieving project assays
#########################################################
num_assays = project["numAssays"]
assays = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/assay/list/project/#{pid}?show=#{num_assays}")
#assays = JSON.parse(File.open("sample_data/assays.json").read)["list"]

assays.each do |assay|
  assay_uri = base_uri + pid + "/assays/" + assay["assayAccession"]
  puts "#{uri_p(project_uri)} #{uri_p(pride + "has_assay")} #{uri_p(assay_uri)} ."
  puts "#{uri_p(assay_uri)} #{uri_p(rdf + "type")} <http://www.ebi.ac.uk/pride/rdf/Assay> ."

  generate_rdf(assay_uri, assay)

  
  #########################################################
  #  retrieving proteins in assay
  #########################################################
  proteins = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/protein/list/assay/#{assay["assayAccession"]}?show=#{assay["proteinCount"]}")
  #proteins = JSON.parse(File.open("sample_data/proteins.json").read)["list"]
  proteins.each do |protein|
    protein_uri = [assay_uri, protein["accession"]].join("/")
    puts "#{uri_p(assay_uri)} <http://www.ebi.ac.uk/pride/rdf/has_protein> #{uri_p(protein_uri)} ."
    puts "#{uri_p(protein_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/Protein> ."
    
    generate_rdf(protein_uri, protein)
    #break
  end
  
  
  #########################################################
  #  retrieving peptides in assay
  #########################################################
  peptides = get_jsons("http://wwwdev.ebi.ac.uk/pride/ws/archive/peptide/list/assay/#{assay["assayAccession"]}?show=#{assay["peptideCount"]}")
  #peptides = JSON.parse(File.open("sample_data/peptides.json").read)["list"]
  peptides.each do |peptide|
    peptide_uri = "http://www.ebi.ac.uk/pride/archive/projects/PXD001328/assays/39777/#{peptide["id"]}"
    puts "#{uri_p(assay_uri)} <http://www.ebi.ac.uk/pride/rdf/detected_peptide> #{uri_p(peptide_uri)} ."
    puts "#{uri_p(peptide_uri)} <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.ebi.ac.uk/pride/rdf/Peptide> ."
    
    generate_rdf(peptide_uri, peptide)
    #break
  end

  #break
end
