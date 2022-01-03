pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./Erc20.sol";

contract Disney {

    ERC20 private token;
    address payable owner;

    struct customer {
        string firstname;
        string lastname;
        uint tokens_owned;
        string[] atractions_took;
    }

    struct Attraction {
        string attraction;
        uint attractionPrice;
        bool attractionStatus;
        uint8 attractionSeats;
    }

    struct Food {
        string name;
        uint foodPrice;
        bool available;
    }

    // Mapping que asocia el nombre con el objeto atraccion
    mapping (string => Attraction) public AttractionMap;
    // Historial de atracciones que ha disfrutado un cliente
    mapping (address => mapping(string => Attraction[])) History;

    // Historial del cliente
    mapping (address => string[]) CustomerHistory;

    mapping (string => Food) public FoodMap;
    // Comidas ordenadas en disney
    mapping (address => Food[]) foodsOrdered;
    
    // Atracciones que posee el parque
    string[] Attractions;
    // Comidas
    string[] foods;


    // Events
    event newAttraction(string, uint);
    event attractionIsDown(string);
    event attractionAdquired(string);
    event FoodOrdered(address, string, uint);
    event newFood(string, uint);

    mapping (address => customer) public Customer;

    constructor(uint initialSupply) public {
        token = new ERC20(initialSupply);
        owner = msg.sender;
    }

    function tokenPrice(uint _numTokens) internal pure returns (uint) {
        return _numTokens * (1 ether);
    }

    function buyTokens(uint _qty) public payable {
        // Paso 1 , hace la conversion de tokens
        uint txCost = tokenPrice(_qty);
        // Paso 2 verificamos que esta persona pueda costear esta transaccion
        require(msg.value >= txCost);
        // Paso 3, restamos el balance actual con el costo
        uint returnValue = (msg.value - txCost);
        // Paso 4, devolvemos la diferencia al comprador, es decir el "vuelto"
        msg.sender.transfer(returnValue);
        // Paso 5 consulta el balance en tokens (Supply)
        require(_qty <= balanceOfCoinMarket());
        // Paso 6, hacemos la transferencia
        token.transfer(msg.sender, _qty);
        // Paso 7, asignamos esta propiedad a los tokens comprados
        Customer[msg.sender].tokens_owned += _qty;
    }

    function balanceOfCoinMarket() public view returns(uint) {
        // Consulta el balance en tokens que posee el contrato del token como tal
        return token.balanceOf(address(this));
    }

    function addTokenSupply(uint tokenAmount) public CanRequest(msg.sender) {
        token.increaseTotalSupply(tokenAmount);
    }

    // Modifier [Guard] para que solo el contrato pueda generar mas tokens
    modifier CanRequest(address _requesting) {
        require(_requesting == owner, "Unhauthorized");
        _;
    }

    // Funcion que se encarga de crear una nueva atraccion
    function addNewAttraction(string memory attractionName, uint price, uint8 seats) public CanRequest(msg.sender) {
        // Asocia el objeto de atraccion con el nombre del parque
        AttractionMap[attractionName] = Attraction(attractionName, price, true, seats);
        // Colocamos el arreglo de atracciones
        Attractions.push(attractionName);
        // Emitimos un Evento
        emit newAttraction(attractionName, price);
    }

    // Funcion que da de baja a una atraccion
    function turnOffAnAttraction(string memory attractionName) public CanRequest(msg.sender) {
        require(AttractionMap[attractionName].attractionStatus, "This attraction doesnt exists, or is currently unavailable");
        AttractionMap[attractionName].attractionStatus = false;
        emit attractionIsDown(attractionName);
    }

    // Devuelve las atracciones disponibles
    function getAttractions() public view returns(string [] memory) {
        return Attractions;
    }

    // Paga un usuario a disney por subirse a una atraccion
    function payAttraction(string memory attractionName) public {
        // Primer paso verificamos si esa atraccion esta disponible
        require(AttractionMap[attractionName].attractionStatus, "This attraction doesnt exists, or is currently unavailable");
        // Segundo paso, verificamos que tengamos la cantidad de dinero disponible para pagar
        require(AttractionMap[attractionName].attractionPrice <= token.balanceOf(msg.sender));
        // Tercer paso, iniciamos la transferencia a disney
        token.transferByParameters(msg.sender, address(this), AttractionMap[attractionName].attractionPrice);
        // Cuarto paso agregamos el historico de disney
        History[msg.sender][attractionName].push(Attraction(attractionName, AttractionMap[attractionName].attractionPrice, true, AttractionMap[attractionName].attractionSeats));
        // Quinto paso agregamos al historico del cliente
        CustomerHistory[msg.sender].push(attractionName);
        // Emitimos el Evento
        emit attractionAdquired(attractionName);

    }

    // Retorna el historial de una attraccion en especifico
    function histories(string memory attraction) public view CanRequest(msg.sender) returns(Attraction[] memory) {
        return History[msg.sender][attraction];
    }

    // Retorna el historial de un cliente
    function customerHistory() public view returns(string[] memory) {
        return CustomerHistory[msg.sender];
    }

    /****************************************** Comida disney ****************************************/
    function addNewFoodToDisney(string memory foodName, uint foodPrice, bool foodAvailable) public CanRequest(msg.sender) {
        FoodMap[foodName] = Food(foodName, foodPrice, foodAvailable);
        foods.push(foodName);
        newFood(foodName, foodPrice);
    }

    function getFoods() public view returns(string [] memory) {
        return foods;
    }

    function getOrders() public view returns(Food[] memory) {
        return foodsOrdered[msg.sender];
    }

    function newOrder(string memory foodName) public {
        require(FoodMap[foodName].available, "This food is unavailable or doesnt exist");
        require(FoodMap[foodName].foodPrice <= token.balanceOf(msg.sender));
        token.transferByParameters(msg.sender, address(this), FoodMap[foodName].foodPrice);
        foodsOrdered[msg.sender].push(Food(foodName, FoodMap[foodName].foodPrice, FoodMap[foodName].available));
        emit FoodOrdered(msg.sender, foodName, FoodMap[foodName].foodPrice);

    }
}