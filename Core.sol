pragma solidity ^0.4.11;

/*
    Банки, курирующие сделки
*/
contract Banks {
    address public bankSupplier; // Банк РФ Поставщика;
    address public bankDistributor; // Банк Покупателя (РФ или иностранный);
    
    modifier onlyBankSupplier {
        if(bankSupplier != msg.sender) revert();
        _;
    }
    
    modifier onlyBankDistributor {
        if(bankDistributor != msg.sender) revert();
        _;
    }
}

/*
    Транспортная компания
*/

contract TransportCompany {
    address public transportCompany;
    
    modifier onlyTransportCompany {
        if(transportCompany != msg.sender) revert();
        _;
    }
}

/*
    Стороны, участвующие в сделках
*/
contract Parties {
    address public supplier; // Поставщик – организация, продавец продукции из РФ;
    address public distributor; // Организация, приобретающая товар и реализующая его Конечному Покупателю;
        
    modifier onlySupplier {
        if(supplier != msg.sender) revert();
        _;
    }
    
    modifier onlyDistributor {
        if(distributor != msg.sender) revert();
        _;
    }
}

contract Contributors is Parties, Banks, TransportCompany {
    mapping (string => bool) documents;
    
    function isApproved(string _documentHash) external returns (bool) {
        return documents[_documentHash];
    }
}


contract Core is Contributors {
    
    enum Stages {
        Initial,
        CreatedByDistributor,
        ApprovedBySupplier,
        CreditRequested,
        CreditFromBankDistributor,
        ApprovedByBankSupplier,
        NotificationSentForSupplierAboutCredit, 
        GoodsAreShippedToTransportCompany,
        TransportInvoiceSent,
        GoodsInvoiceSent,
        TransportInvoiceApproved,
        GoodsInvoceApproved,
        CoverLetterSent,
        PaymentSendFromBankDistributor,
        PaymentConfirmed,
        NotificationSentForSupplierAboutPayment,
        IncorporationDocumentsSent,
        GoodsAreShippedToDistributor,
        GoodsAreReceived
    }
    
    event DocumentInfo(string _type, string _documentHash, address _who);
    event StageInfo(string _stage);
    event InvalidTransition(string _message);
    
    Stages public currentStage = Stages.Initial;
    
    function Core(address _bankSupplier, address _bankDistributor, address _transportCompany, 
                        address _supplier, address _distributor) {
        bankSupplier = _bankSupplier;
        bankDistributor = _bankDistributor;
        transportCompany = _transportCompany;
        supplier = _supplier;
        distributor = _distributor;
    }
    
    function createByDistributor(string _documentHash) onlyDistributor external {
        if (currentStage == Stages.Initial) {
            documents[_documentHash] = false;
            currentStage = Stages.CreatedByDistributor;
            DocumentInfo("Contract", _documentHash, msg.sender);
            StageInfo("Created by distributor");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function approveBySupplier(string _documentHash) onlySupplier external {
        if (currentStage == Stages.CreatedByDistributor) {
            documents[_documentHash] = true;
            currentStage = Stages.ApprovedBySupplier;
            DocumentInfo("Contract", _documentHash, msg.sender);
            StageInfo("Approved by supplier");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function creditRequest() onlyDistributor external {
        if (currentStage == Stages.ApprovedBySupplier) {
            currentStage = Stages.CreditRequested;
            StageInfo("Credit requested");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function creditFromBankDistributor(string _documentHash) onlyBankDistributor external {
        if (currentStage == Stages.CreditRequested) {
            documents[_documentHash] = false;
            currentStage = Stages.CreditFromBankDistributor;
            DocumentInfo("Credit", _documentHash, msg.sender);
            StageInfo("Credit from bank distributor");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function approvedByBankSupplier(string _documentHash) onlyBankSupplier external {
        if (currentStage == Stages.CreditFromBankDistributor) {
            documents[_documentHash] = true;
            currentStage = Stages.ApprovedByBankSupplier;
            DocumentInfo("Credit", _documentHash, msg.sender);
            StageInfo("Approved by bank supplier");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function notifySupplierAboutCredit(string _documentHash) onlyBankSupplier external {
        if (currentStage == Stages.ApprovedByBankSupplier) {
            documents[_documentHash] = true;
            currentStage = Stages.NotificationSentForSupplierAboutCredit;
            DocumentInfo("Notification for supplier about credit", _documentHash, msg.sender);
            StageInfo("Notification sent for supplier about credit");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function goodsShipmentToTransportCompany() onlySupplier external {
        if (currentStage == Stages.NotificationSentForSupplierAboutCredit) {
            currentStage = Stages.GoodsAreShippedToTransportCompany;
            StageInfo("Goods are shipped to transport company");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function transportInvoiceSending(string _documentHash) onlyTransportCompany external {
        if (currentStage == Stages.GoodsAreShippedToTransportCompany) {
            documents[_documentHash] = false;
            currentStage = Stages.TransportInvoiceSent;
            DocumentInfo("Transport invoice", _documentHash, msg.sender);
            StageInfo("Transport invoice sent");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function goodsInvoiceSending(string _documentHash) onlySupplier external {
        if (currentStage == Stages.TransportInvoiceSent) {
            documents[_documentHash] = false;
            currentStage = Stages.GoodsInvoiceSent;
            DocumentInfo("Goods invoice", _documentHash, msg.sender);
            StageInfo("Goods invoice sent");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function transportInvoiceApprove(string _documentHash) onlyBankDistributor external {
        if (currentStage == Stages.GoodsInvoiceSent) {
            documents[_documentHash] = true;
            currentStage = Stages.TransportInvoiceApproved;
            DocumentInfo("Transport invoice", _documentHash, msg.sender);
            StageInfo("Transport invoice approved");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function goodsInvoceApprove(string _documentHash) onlyBankDistributor external {
        if (currentStage == Stages.TransportInvoiceApproved) {
            documents[_documentHash] = true;
            currentStage = Stages.GoodsInvoceApproved;
            DocumentInfo("Goods invoice", _documentHash, msg.sender);
            StageInfo("Goods invoce approved");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function coverLetterSending(string _documentHash) onlyBankDistributor external {
        if (currentStage == Stages.GoodsInvoceApproved) {
            documents[_documentHash] = true;
            currentStage = Stages.CoverLetterSent;
            DocumentInfo("Cover letter", _documentHash, msg.sender);
            StageInfo("Cover letter sent");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function paymentSendingFromBankDistributor(string _documentHash) onlyBankDistributor external {
        if (currentStage == Stages.CoverLetterSent) {
            documents[_documentHash] = false;
            currentStage = Stages.PaymentSendFromBankDistributor;
            DocumentInfo("Receipt", _documentHash, msg.sender);
            StageInfo("Payment send from bank distributor");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function paymentConfirm(string _documentHash) onlyBankSupplier external {
        if (currentStage == Stages.PaymentSendFromBankDistributor) {
            documents[_documentHash] = true;
            currentStage = Stages.PaymentConfirmed;
            DocumentInfo("Receipt", _documentHash, msg.sender);
            StageInfo("Payment confirmed");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
    
    function notifySupplierAboutPayment(string _documentHash) onlyBankSupplier external {
        if (currentStage == Stages.PaymentConfirmed) {
            documents[_documentHash] = true;
            currentStage = Stages.NotificationSentForSupplierAboutPayment;
            DocumentInfo("Notification for supplier about payment", _documentHash, msg.sender);
            StageInfo("Notification sent for supplier about payment");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }

    function incorporationDocumentsSending(string _documentHash) onlyDistributor external {
        if (currentStage == Stages.NotificationSentForSupplierAboutPayment) {
            documents[_documentHash] = true;
            currentStage = Stages.IncorporationDocumentsSent;
            DocumentInfo("Incorporation documents", _documentHash, msg.sender);
            StageInfo("Incorporation documents sent");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }

    function goodsShippingToDistributor() onlyTransportCompany external {
        if (currentStage == Stages.IncorporationDocumentsSent) {
            currentStage = Stages.GoodsAreShippedToDistributor;
            StageInfo("Goods are shipped to distributor");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }

    function goodsReceiving() onlyDistributor external {
        if (currentStage == Stages.GoodsAreShippedToDistributor) {
            currentStage = Stages.GoodsAreReceived;
            StageInfo("Goods are received");
        } else {
            InvalidTransition("Cannot change stage to requested stage");
            revert();
        }
    }
}