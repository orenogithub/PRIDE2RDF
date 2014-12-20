prefix     = "@prefix pride: <http://www.ebi.ac.uk/pride/rdf/> ."
out_folder = "/Volumes/orenostorage/PRIDE/turtle/"
files      = Dir.glob("/Volumes/orenostorage/PRIDE/RDF/*")

#########################################################
#  resume
#########################################################
=begin
skip = "PRD000659"
skip = files.index("/Volumes/orenostorage/PRIDE/RDF/#{skip}.nt")
files.shift(skip)
=end

# test data
#files = ["/Volumes/orenostorage/PRIDE/RDF/PRD000594.nt"]


files.each do |file|
  accession = file.split("/")[-1].sub(/nt/, "ttl")
  puts accession

#=begin
  # delete illegal characters in URI
  out = File.open("#{file}2", "w")
  File.open(file).each do |line|
    line = line.chomp.delete("|").gsub(/\\/, "/")
    if line =~ /<.+?,\s.+?>/
      line = line.gsub(/,\s/, "_and_")
    end
    if line =~ /<.+?\s.+?>/
      line = line.gsub(/\s/, "_")
      line = line.gsub(/_</, " <").sub(/_\"/, " \"").sub(/__:/, " _:").sub(/_\.$/, " .")
    end
    out.puts line  
  end
  out.close
  File.rename("#{file}2", file)
#=end

=begin
  # delete illegal character in URI (cause error for large data >2G?)
  open(file, "r+") do |f|
    f.flock(File::LOCK_EX)
    out  = Array.new
    body = f.read
    body.split("\n").each do |line|
      line = line.delete("|").gsub(/\\/, "/")
      if line =~ /<.+?,\s.+?>/
        line = line.gsub(/,\s/, "_and_")
      end
      if line =~ /<.+?\s.+?>/
        line = line.gsub(/\s/, "_")
        line = line.gsub(/_</, " <").sub(/_\"/, " \"").sub(/__:/, " _:").sub(/_\.$/, " .")
      end
      out << line
    end  
    
    f.rewind
    f.puts out.join("\n")
    f.truncate(f.tell)
  end
=end  
  
#=begin
  # convert ntriples format to turtle format in order to reduce a file size and check a grammar
  ttl = `/usr/local/bin/rapper -i ntriples -o turtle #{file}`

  
  # replace URL into prefix:value in order to reduce file size
  out = File.open("#{out_folder}/#{accession}", "w")
  out.puts prefix
  ttl.split("\n").each do |line|
    if line =~ /http\:\/\/www.ebi.ac.uk\/pride\/rdf\//
      line = line.sub(/<http\:\/\/www.ebi.ac.uk\/pride\/rdf\//, "pride:").sub(/>/, "")
      out.puts line
    else
      out.puts line
    end
  end
  ttl = ""
  out.close
#=end
end