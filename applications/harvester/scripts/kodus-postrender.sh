#!/bin/sh
# Postrender for the kodus helm release.
#
# The chart hardcodes the /tmp emptyDir sizeLimit at 100Mi (kodus-common.tmpVolume)
# with no values knob. Review agents scratch in /tmp (repo clones, AST graphs,
# local sandbox work) and exceed 100Mi on real reviews, which triggers an
# immediate kubelet eviction ("Usage of EmptyDir volume tmp exceeds the limit")
# and kills in-flight reviews. Lift the cap to 5Gi (a limit, not a reservation).
sed 's/sizeLimit: 100Mi/sizeLimit: 5Gi/'
