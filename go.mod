module kairos.io/kairos

go 1.27.1

require (
	kairos.io/apis v0.0.0
)

replace (
	kairos.io/apis => ./staging/src/kairos.io/apis
)