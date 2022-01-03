# Genotyping

After constructing a graph we want to use it to genotype our short read samples. I am currently testing to different approaches:

* Mapping with [vg giraffe](https://www.science.org/doi/10.1126/science.abg8871) then calling genotypes with vg call.

* [Pangenie](https://github.com/eblerjana/pangenie) genotyping without read mapping. 