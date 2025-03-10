%.pdf: %.rst
	rst2pdf -s rst.css -o $@ -l de $<


README.pdf: README.rst
