#!/bin/bash

echo "Generating index.html..."

cat <<EOF > index.html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Ideas</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
</head>

<body>
    <h1>Project Ideas</h1>
    <ul>
EOF

for file in *.md; do
    if [[ -f "$file" && "$file" != "README.md" ]]; then
        echo "        <li><a href=\"#\" class=\"md-link\" data-src=\"$file\">$file</a></li>" >> index.html
    fi
done

cat <<EOF >> index.html
    </ul>

    <!-- Modal -->
    <div id="modal" class="modal">
        <div class="modal-content">
            <span class="close-modal" onclick="closeModal()">&times;</span>
            <div id="modal-body">Loading...</div>
        </div>
    </div>

    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const links = document.querySelectorAll(".md-link");

            links.forEach(link => {
                link.addEventListener("click", function (e) {
                    e.preventDefault();
                    openModal(link.getAttribute("data-src"));
                });
            });
        });

        function openModal(mdFile) {
            const modal = document.getElementById("modal");
            const modalBody = document.getElementById("modal-body");

            modal.style.display = "block";
            modalBody.innerHTML = "Loading...";

            fetch(mdFile)
                .then(response => response.text())
                .then(data => {
                    modalBody.innerHTML = marked.parse(data);
                })
                .catch(error => {
                    modalBody.innerHTML = "<p style='color: red;'>Failed to load content: " + error + "</p>";
                });
        }

        function closeModal() {
            document.getElementById("modal").style.display = "none";
        }

        window.onclick = function (event) {
            const modal = document.getElementById("modal");
            if (event.target === modal) {
                closeModal();
            }
        }
    </script>
</body>

</html>
EOF

echo "index.html generated!"
