pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string URL;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    constructor() public{
        owner = msg.sender;
    }
    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() { 
        require (msg.sender == owner); 
        _; 
    }

    modifier isOpen(uint eventId) { 
        require (events[eventId].isOpen); 
        _; 
    }

    modifier paidEnough(uint tickets) { 
        require (msg.value >= tickets * PRICE_TICKET); 
        _; 
    }

    modifier enoughTickets(uint eventId, uint tickets) { 
        require (events[eventId].totalTickets >= tickets); 
        _; 
    }
    
    modifier checkValue(uint tickets) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint cost = tickets * PRICE_TICKET;
        uint amountToRefund = msg.value - cost;
        msg.sender.transfer(amountToRefund);
    }
    

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent (string memory _description, string memory _URL, uint _totalTickets) 
        onlyOwner()
        public
        returns(uint)
    {
        uint eventId = idGenerator;
        events[eventId].description = _description;
        events[eventId].URL = _URL;
        events[eventId].totalTickets = _totalTickets;
        events[eventId].isOpen = true;
        events[eventId].sales = 0;
        idGenerator ++;
        emit LogEventAdded(_description, _URL, _totalTickets, eventId);
        return eventId;
    }
    

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */  
    function readEvent (uint eventId) view public returns(string memory, string memory, uint, uint, bool) {
        return (events[eventId].description, events[eventId].URL, events[eventId].totalTickets, events[eventId].sales, events[eventId].isOpen);     
    }
          

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets (uint eventId, uint tickets)
        isOpen(eventId)
        paidEnough(tickets)
        enoughTickets(eventId, tickets)
        checkValue(tickets)
        payable
        public
    {
        events[eventId].sales += tickets;
        events[eventId].totalTickets -= tickets;
        events[eventId].buyers[msg.sender] += tickets;
        emit LogBuyTickets(msg.sender, eventId, tickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund (uint eventId) public {
        uint currentTickets = events[eventId].buyers[msg.sender];
        require (currentTickets > 0);
        events[eventId].sales -= currentTickets;
        events[eventId].totalTickets += currentTickets;
        msg.sender.transfer(currentTickets * PRICE_TICKET);
        emit LogGetRefund(msg.sender, eventId, currentTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets (uint eventId) 
        view
        public
        returns(uint) 
    {
        return events[eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale (uint eventId) 
        public 
        onlyOwner()
    {
        events[eventId].isOpen = false;
        owner.transfer(events[eventId].sales * PRICE_TICKET);
        emit LogEndSale(owner, events[eventId].sales * PRICE_TICKET, eventId);
    }
}
