Class {
	#name : 'FBTestTaskBehavior',
	#superclass : 'FBTaskBehavior',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBTestTaskBehavior class >> metadataSchema [ 
	^ { 
		#status -> FBPropertyType string.
		#pid -> FBPropertyType number  } asPropertySchema
]

{ #category : 'as yet unclassified' }
FBTestTaskBehavior class >> propertySchema [ 
	^ { 
		#name -> FBPropertyType string.
		#age -> FBPropertyType number  } asPropertySchema
]

{ #category : 'execution' }
FBTestTaskBehavior >> execute [ 
	self activation metadataAt: #status put: 200
	
]
