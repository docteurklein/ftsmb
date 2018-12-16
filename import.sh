
uri=$1
echo $uri

psql 'host=0 user=postgres' -v uri="$uri" -v content="$(curl -sL $uri | tr -d '"')" <<< "insert into input_stream(uri, content) values(:'uri', :'content')"
