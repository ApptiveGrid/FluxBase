Class {
	#name : 'FBFlowEvent',
	#superclass : 'Object',
	#instVars : [
		'timestamp'
	],
	#category : 'FluxBase-Core-Event',
	#package : 'FluxBase-Core',
	#tag : 'Event'
}

{ #category : 'testing' }
FBFlowEvent class >> handlesAnnouncement: anAnnouncement [
	^ anAnnouncement class includesBehavior: self 
]

{ #category : 'conversion' }
FBFlowEvent >> asAnnouncement [
	^ self
]

{ #category : 'accessing' }
FBFlowEvent >> initialize [

	super initialize.
	timestamp := DateAndTime now
]

{ #category : 'accessing' }
FBFlowEvent >> message [

	^ self subclassResponsibility 
]

{ #category : 'accessing' }
FBFlowEvent >> name [

	^ self subclassResponsibility 
]

{ #category : 'initialization' }
FBFlowEvent >> prepareForDelivery [
	"nothing to do"
]

{ #category : 'accessing' }
FBFlowEvent >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
FBFlowEvent >> type [

	^ self subclassResponsibility 
]
