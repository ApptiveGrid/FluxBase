Class {
	#name : 'BaselineOfFluxBase',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfFluxBase',
	#package : 'BaselineOfFluxBase'
}

{ #category : 'baselines' }
BaselineOfFluxBase >> baseline: spec [
	<baseline>
	spec for: #'common' do: [
		spec 
			package: 'FluxBase-Core' with: [ 
				spec requires: #() ];
			package: 'FluxBase-Core-Tests' with: [ 
				spec requires: #('FluxBase-Core') ];
			package: 'FluxBase-Roassal' with: [
				spec requires: #('FluxBase-Core') ].
			
		spec 
			group: 'Core' with: #('FluxBase-Core' 'FluxBase-Core-Tests');
			group: 'Dev' with: #( 'Core' 'FluxBase-Roassal' );
			group: 'default' with: #( 'Dev' ) ]
]
