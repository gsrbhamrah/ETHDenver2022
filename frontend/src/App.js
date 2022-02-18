import React, { useEffect, useState, } from "react";
import { ethers } from "ethers";
import './styles/App.css';
import abi from './utils/PlaylistPortal.json';
import twitterLogo from './assets/twitter-logo.svg';

const App = () => {
  const [currentAccount, setCurrentAccount] = useState("");
  const contractAddress = " ";
  const contractABI = abi.abi;

  const TWITTER_HANDLE = 'gsrb_';
  const TWITTER_LINK = `https://twitter.com/${TWITTER_HANDLE}`;

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

  useEffect(() => {
    checkIfWalletIsConnected();
  })
  
  // Render Methods
  const renderNotConnectedContainer = () => (
    <button onClick={connectWallet} className="cta-button connect-wallet-button">
      Connect to Wallet
    </button>
  );

  const renderMintUI = () => (
    <button className="cta-button mint-button">
      haha button
    </button>
  );
  
  return (
    <div className="App">
      <div className="container">
        <div className="header-container">
          <p className="header gradient-text">FIDES</p>
          <p className="sub-text">
            hello there. currently in construction
          </p>
          {currentAccount === "" ? renderNotConnectedContainer() : renderMintUI()}
        </div>
        <div className="footer-container">
          <img alt="Twitter Logo" className="twitter-logo" src={twitterLogo} />
          <a
            className="footer-text"
            href={TWITTER_LINK}
            target="_blank"
            rel="noreferrer"
          >{TWITTER_HANDLE}</a>
        </div>
      </div>
    </div>
  );
};
export default App