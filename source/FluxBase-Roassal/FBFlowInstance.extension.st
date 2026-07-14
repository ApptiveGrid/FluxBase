Extension { #name : 'FBFlowInstance' }

{ #category : '*FluxBase-Roassal' }
FBFlowInstance >> inspectionFlow: aBuilder [
	<inspectorPresentationOrder: 0 title: 'flow'>
	^ aBuilder newRoassal
		canvas: (FBFlowMapBuilder new
			nodes: flow nodes;
			activations: self rootExecutor activations;
			build )
		yourself
]
