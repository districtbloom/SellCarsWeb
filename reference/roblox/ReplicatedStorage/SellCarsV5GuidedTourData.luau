-- Studio review steps, not purchase-pad entitlements.
return {
 MoveSeconds=.65, BeforeSeconds=2.25, AfterSeconds=3.0,
 Steps={
  {Title='Raise the gallery roof',Caption='The same deck and columns remain. Taller glazing and a raised lantern replace the lower closed roof.',Before=0,After=1,
   Camera=Vector3.new(3190,65,357),LookAt=Vector3.new(3105,28,431),Focus='Roof'},
  {Title='Grow the collection from four to six',Caption='Two centre display positions, their cars, lights and records join the four existing corner exhibits.',Before=1,After=2,
   Camera=Vector3.new(3147,30,455),LookAt=Vector3.new(3100,25,425),Focus='Exhibits'},
  {Title='Refine the materials',Caption='Concrete and coated-metal finishes become limestone, timber soffits and warm metal accents. The structure stays put.',Before=2,After=3,
   Camera=Vector3.new(3119,29,455),LookAt=Vector3.new(3119,27,411),Focus='Materials'},
  {Title='See the complete Collector transformation',Caption='Compare the whole Collector study with its Institution version. The rest of the campus is unchanged.',Before=0,After=3,
   Camera=Vector3.new(3190,65,357),LookAt=Vector3.new(3105,28,431),Focus='Overview'}
 }
}

