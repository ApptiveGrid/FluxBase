Extension { #name : 'FBNode' }

{ #category : '*FluxBase-Roassal' }
FBNode >> asRoassalShape [
	^ RSLabel new text: 'N/A'
]

{ #category : '*FluxBase-Roassal' }
FBNode >> inspectionFlow: aBuilder [
	<inspectorPresentationOrder: 0 title: 'flow'>
	^ aBuilder newRoassal
		canvas: (FBFlowMapBuilder new
			nodes: self neighbourNodes;
			build )
		yourself
]
