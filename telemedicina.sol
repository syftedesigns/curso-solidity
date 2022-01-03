pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./Erc20.sol";

contract InsuranceFactory {

    address payable owner;
  
    ERC20 token;

    address public InsuranceContract;


    // Estructura para los servicios
    struct services {
        string name;
        bool available;
        uint cost;
        address provider;
    }

    // Estructura para las polizas
    struct HealthRecord {
        bytes32 user; // Hash de lso datos del usuario
        address userDirection;
        address userContract; // El contrato de la poliza,
        uint insuranceTokens; // Saldo Tokens de la poliza
    }

    // Asocia una direccion con una poliza
    mapping (address => HealthRecord) poliza;

    mapping (address => uint) balance;

    // Asocia servicios a una direccion
    mapping (address => services[]) serviciosPoliza;

    mapping (string => services) mapServicio;

    string[] public servicios; // Muestra todos los servicios que ofrece la aseguradora

    services[] internal serviciosAlmacenados;

    // Solicitudes de laboratorio (Un arreglo de direcciones)
    address[] SolicitudesDePropiedadLaboratorio;
    

    // parametro 1: Direccion del emisor, Parametro 2: Direccion del contrato de la poliza
    event nuevaPoliza(address, address);
    // Cuando la aseguradora registra un nuevo servicio a su repertorio
    event nuevoServicio(services);
    // Direccion 
    event bajaPoliza(address);

    constructor(uint initialSupply) public {
        token = new ERC20(initialSupply);
        owner = msg.sender;
        InsuranceContract = address(this);
    }


/************************************* FUNCIONES /**************************************************/
// SERVICIOS
function registraNuevoServicio(string memory _nombre, bool disponible, uint costo) public Propietario(msg.sender) {
    mapServicio[_nombre] = services(_nombre, disponible, costo, address(this));
    servicios.push(_nombre);
    serviciosAlmacenados.push(services(_nombre, disponible, costo, address(this)));
    emit nuevoServicio(services(_nombre, disponible, costo, address(this)));
}

function getServicios() public view returns(string [] memory) {
    return servicios;
 }

function getDatoServicio(string memory _nombreServicio) public view returns (services memory) {
    return mapServicio[_nombreServicio];
}

function bajaServicio(string memory _nombreServicio) public Propietario(msg.sender) {
    require(!mapServicio[_nombreServicio].available, "Este servicio ya esta de baja o no existe");
    // Si es true, entonces damos de baja
    mapServicio[_nombreServicio].available = false;
} 

modifier Propietario(address _direccion) {
    require(_direccion == owner, "No esta autorizado, para crear un servicio");
    _;
}
/****************************** FIN SERVICIOS /***************************************/

function compraPoliza(uint numTokens, string memory userId) public payable {
        uint coste = costoToken(numTokens);
        require(msg.value >= coste);
        msg.sender.transfer((msg.value - coste));
        require(numTokens <= balanceOfMarket());
        token.transfer(msg.sender, numTokens);
        balance[msg.sender] += numTokens;
        // Creamos la poliza
        bytes32 USER = keccak256(abi.encodePacked(userId));
        // Genera una nueva poliza
        address contratoPoliza = address(new InsuranceHealthRecord(msg.sender, numTokens, InsuranceContract, serviciosAlmacenados, token));
        // Almacenamos los datos de la nueva poliza
        poliza[msg.sender] = HealthRecord(USER, msg.sender, contratoPoliza, numTokens);
        // Emitimos un evento de la poliza
        emit nuevaPoliza(msg.sender, contratoPoliza);

}

function getPoliza(address _addrPropietario) public view Propietario(msg.sender) returns(HealthRecord memory) {
    return poliza[_addrPropietario];
}

// LOTE Tokens
function balanceOfMarket() public view returns(uint) {
    return token.balanceOf(address(this));
}

function costoToken(uint _numTokens) internal pure returns(uint) {
    return _numTokens * (1 ether);
}

}

contract Laboratorio {
    address owner; // Propietario de ese laboratorio
    address direccionDelContrato;



    constructor(address creator) public {
        owner = creator;
        direccionDelContrato = address(this);
    }

    modifier soloLaboratorio(address direccion) {
        require(owner == direccion, "Solo el propietario del laboratorio puede ejecutar esta accion");
        _;
    }



}

// Contrato para gestionar la poliza
contract InsuranceHealthRecord {
    address owner; // Propietario de la poliza
    address contractAddr; // Direccion del contrato de la poliza
    uint balance; // Balance actual
    address mainCompany; // La aseguradora
    ERC20 token;
    
    struct service {
        string name;
        bool available;
        uint cost;
        address provider;
    }

    service[] serviciosAseguradora; // Servicios disponibles por la aseguradora

    string[] serviciosAdquiridos;

    mapping (string => service) mapServicio;

    mapping (address => string[]) history;

    event teleServicio(service, address);
    
    constructor(address _direccion, uint polizaBalance, address aseguradora, service[] memory servicios, ERC20 tokenAseguradora) public {
        owner = _direccion;
        balance = polizaBalance;
        mainCompany = aseguradora;
        serviciosAseguradora = servicios;
        token = tokenAseguradora;
        /*for (uint i = 0; i < serviciosAseguradora.length; i++) {
            mapServicio[i].name = service(serviciosAseguradora[i].name, serviciosAseguradora[i].available, serviciosAseguradora[i].cost, serviciosAseguradora[i].provider);
        }*/
    }

    function getBalance() public view returns(uint) {
        return balance;
    }

    function mostrarServiciosDisponibles() public view returns(service [] memory) {
        return serviciosAseguradora;
    }

    function consultarServicio(string memory _servicio) public view returns(service memory) {
        return mapServicio[_servicio];
    }

    function comprarServicio(string memory _servicio) public {
        require(mapServicio[_servicio].available, "Este servicio no existe o no esta disponible");
        require(balance >= mapServicio[_servicio].cost, "No tienes suficientes tokens en tu poliza para adquirir este servicio");
        token.transferByParameters(msg.sender, mainCompany, mapServicio[_servicio].cost);
        balance -= mapServicio[_servicio].cost;
        history[msg.sender].push(_servicio);
        serviciosAdquiridos.push(_servicio);
        emit teleServicio(mapServicio[_servicio], msg.sender);
    }

    function consultarServiciosAdquiridos() public view returns(string [] memory) {
        return serviciosAdquiridos;
    }

    function consultarHistorico() public view returns (string [] memory) {
        return history[msg.sender];
    }

    modifier propietarioPoliza(address propietario) {
        require(owner == propietario, "No eres el propietario de esta poliza");
        _;
    }


    // Lista de servicios disponibles que tiene la empresa

}