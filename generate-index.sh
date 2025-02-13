#!/bin/bash

# Generate index.html with links to all .md files in the repo root
cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Ideas</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Project Ideas</h1>
    <ul>
EOF

for file in *.md; do
    if [ -f "$file" ]; then
        echo "        <li><a href=\"$file\">$file</a></li>" >> index.html
    fi
done

cat <<EOF >> index.html
    </ul>
</body>
</html>
EOF

echo "index.html updated!"
