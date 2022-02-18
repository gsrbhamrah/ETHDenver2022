import React, { useEffect, useState, } from "react";
import { ethers } from "ethers";
import './styles/App.css';
import abi from './utils/PlaylistPortal.json';

const App = () => {
  const [currentAccount, setCurrentAccount] = useState("");
  const [allPlists, setAllPlists] = useState([]);
  const [plistMessage, setPlistMessage] = useState("");
  const contractAddress = " ";
  const contractABI = abi.abi;

   const useInput = initialValue => {

    return {
      value: plistMessage,
      setValue: setPlistMessage,
      reset: () => setPlistMessage(""),
      bind: {
        plistMessage,
        onChange: event => {
          setPlistMessage(event.target.value);
        }
      }
    };
  };

  const checkIfWalletIsConnected = async () => {
    try {
      const { ethereum } = window;
      
      if (!ethereum) {
        console.log("Make sure you have metamask!");
        return;
      } else {
        console.log("We have the ethereum object", ethereum);
      }

      const accounts = await ethereum.request({ method: 'eth_accounts' });
      
      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Found an authorized account:", account);
        setCurrentAccount(account);
        getAllPlists();

      } else {
        console.log("No authorized account found")
      }
    } catch (error) {
      console.log(error);
    }
  }
  
  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        alert("you need to install metamask on this browser!");
        return;
      }

      const accounts = await ethereum.request({ method: "eth_requestAccounts"});

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]);
    } catch (error) {
      console.log(error)
    }
  }

  const plist = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const plistPortalContract = new ethers.Contract(contractAddress, contractABI, signer);

        let count = await plistPortalContract.getTotalPlists();
        console.log("Retrieved total playlist count...", count.toNumber());

        const plistTxn = await plistPortalContract.plist(plistMessage, {gasLimit: 300000});
        console.log("Mining...", plistTxn.hash)
        alert("Your transaction can be viewed on Etherscan: https://rinkeby.etherscan.io/address/0x46dC1714a478311fDc0bA43BBa2E0E6f00f3Deb9");

        await plistTxn.wait();
        console.log("Mined -- ", plistTxn.hash);

        count = await plistPortalContract.getTotalPlists();
        console.log("Retrieved total playlist count...", count.toNumber());
      } else {
        console.log("Ethereum object doesn't exist!");
        alert("first connect your metamask wallet!")
      }
    } catch (error) {
      console.log(error)
    }
  }

  const getAllPlists = async () => {
    const { ethereum } = window;

    try {
      if (window.ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const plistPortalContract = new ethers.Contract(contractAddress, contractABI, signer);

        const plists = await plistPortalContract.getAllPlists();

        let plistsCleaned = [];
        plists.forEach(plist => {
          plistsCleaned.push({
            address: plist.sharer,
            timestamp: new Date(plist.timestamp * 1000),
            message: plist.message
          });
        });

        setAllPlists(plistsCleaned);

        plistPortalContract.on("NewPlist", (from, timestamp, message) => {
          console.log("NewPlist", from, timestamp, message);

          setAllPlists(prevState => [...prevState, {
            address: from,
            timestamp: new Date(timestamp * 1000),
            message: message
          }]);
        });
      } else {
        console.log("Ethereum object doesn't exist!")
      }
    } catch (error) {
      console.log(error)
    }
  }

  useEffect(() => {
    checkIfWalletIsConnected();
  }, [])
  
  return (
    document.body.style = 'background: #4d5d53',
    <div className="mainContainer">
      <div className="dataContainer">
        <div className="header">
          🎶 hello friend 🎶
        </div>

        <div className="bio">
          <p>this is russ buss speaking, pleased to see ya here :)</p>
          <p>connect your web3 wallet and share a spotify playlist on the ethereum blockchain for a chance to win some ETH!</p>
        </div>

        <div className="reminder">
          <em> be sure to be on the rinkeby testnet</em>
        </div>

        <textarea className="plistTextArea"
            type = "text"
            name = "message"
            placeholder = "share a link to your playlist here!"
            onChange = {e=>setPlistMessage(e.target.value)}
            value = {plistMessage}
        ></textarea>
    
        <button className="plistButton" onClick={plist}>
          share
        </button>

        {!currentAccount && (
          <button className="plistButton" onClick={connectWallet}> connect wallet
          </button>
        )}

        {allPlists.map((plist, index) => {
          return (
            <div key={index} style={{ backgroundColor: 'rgb(65,81,71)', color: 'white', fontSize: "14px", marginTop: "16px", borderRadius: "6px", padding: "16px" }}>
              <div><h3>Shared by:</h3>
              <p>{plist.address}</p>
              </div>
              <div><h3>Shared at:</h3>
              <p>{plist.timestamp.toString()}</p>
              </div>
              <div><h3>Playlist:</h3>
              <p>{plist.message}</p>
              </div>
            </div>)
        })}
      </div>
    </div>
    );
  }
export default App