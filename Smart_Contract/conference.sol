// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Conference {
    // Organizer address
    address public organizer;

    // Struct to represent a paper submission
    struct Paper {
        uint id;
        address speaker;
        string title;
        string content;
        uint votes;
    }

    // Yha pe hum event struct bana rhe h
    struct Event {
        uint id;
        string name;
        uint date;
        string description;
        address[] speakers;
        bool isCompleted;
        mapping(uint => Paper) papers;
        uint nextPaperId;
        mapping(address => bool) hasVoted; // This is to  Track which attendees have voted
    }

    // Mapping to store events by ID
    mapping(uint => Event) public events;
    uint public nextEventId; // Counter to generate unique IDs

    // Modifier to restrict access to the organizer
    modifier onlyOrganizer() {
        require(msg.sender == organizer, "Not authorized");
        _;
    }

    // Modifier to restrict access to event speakers
    modifier onlySpeaker(uint _eventId) {
        bool isSpeaker = false;
        for (uint i = 0; i < events[_eventId].speakers.length; i++) {
            if (events[_eventId].speakers[i] == msg.sender) {
                isSpeaker = true;
                break;
            }
        }
        require(isSpeaker, "Not a speaker for this event");
        _;
    }

    // Event emitted when a new event is created
    event EventCreated(uint eventId, string eventName, uint eventDate);

    // Event emitted when a new paper is submitted
    event PaperSubmitted(uint eventId, uint paperId, address speaker, string paperTitle);

    // Event emitted when a vote is cast
    event VoteCast(uint eventId, uint paperId, address attendee);

    // Constructor to set the initial organizer
    constructor() {
        organizer = msg.sender;
    }

    // Function to create a new event
    function createEvent(string memory _name, uint _date, string memory _description, address[] memory _speakers) public onlyOrganizer {
        require(bytes(_name).length > 0, "Event name is required");
        require(_date > block.timestamp, "Event date must be in the future");
        require(_speakers.length > 0, "At least one speaker is required");

        // Create the new event
        Event storage newEvent = events[nextEventId];
        newEvent.id = nextEventId;
        newEvent.name = _name;
        newEvent.date = _date;
        newEvent.description = _description;
        newEvent.speakers = _speakers;
        newEvent.isCompleted = false;

        // Emit the event creation log
        emit EventCreated(nextEventId, _name, _date);

        // Increment the event ID counter
        nextEventId++;
    }

    // Function for speakers to submit a paper
    function submitPaper(uint _eventId, string memory _title, string memory _content) public onlySpeaker(_eventId) {
        require(bytes(_title).length > 0, "Paper title is required");
        require(bytes(_content).length > 0, "Paper content is required");

        Event storage eventInstance = events[_eventId];
        uint paperId = eventInstance.nextPaperId;
        eventInstance.papers[paperId] = Paper({
            id: paperId,
            speaker: msg.sender,
            title: _title,
            content: _content,
            votes: 0
        });

        // Emit the paper submission log
        emit PaperSubmitted(_eventId, paperId, msg.sender, _title);

        // Increment the paper ID counter
        eventInstance.nextPaperId++;
    }

    // Function for attendees to vote on a paper
    function voteOnPaper(uint _eventId, uint _paperId) public {
        Event storage eventInstance = events[_eventId];

        // Ensure the event is ongoing or not yet completed
        require(block.timestamp < eventInstance.date + 7 days, "Voting period is over");

        // Ensure the attendee hasn't already voted
        require(!eventInstance.hasVoted[msg.sender], "You have already voted");

        // Ensure the paper exists
        require(eventInstance.papers[_paperId].speaker != address(0), "Paper not found");

        // Cast the vote
        eventInstance.papers[_paperId].votes++;

        // Mark the attendee as having voted
        eventInstance.hasVoted[msg.sender] = true;

        // Emit the vote cast event
        emit VoteCast(_eventId, _paperId, msg.sender);
    }

    // Function to get the details of a paper
    function getPaperDetails(uint _eventId, uint _paperId) public view returns (address, string memory, string memory, uint) {
        Paper storage paper = events[_eventId].papers[_paperId];
        return (paper.speaker, paper.title, paper.content, paper.votes);
    }

    // Additional functions can be added to fetch event or speaker data as needed
}
