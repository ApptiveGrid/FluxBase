Extension { #name : 'FBWait' }

{ #category : '*FluxBase-Roassal' }
FBWait >> asRoassalShape [
	^ RSBox new
		size: 50;
		color: (Color green );
		cornerRadius: 0;
		model: self;
		yourself
]
