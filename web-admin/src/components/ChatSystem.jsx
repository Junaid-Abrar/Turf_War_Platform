import { useState, useEffect, useContext } from 'react';
import { db } from '../api/firebase';
import { collection, query, where, onSnapshot, orderBy, addDoc, serverTimestamp, doc, setDoc } from 'firebase/firestore';
import { Row, Col, ListGroup, Form, Button, Card, Badge } from 'react-bootstrap';
import AuthContext from '../context/AuthContext';
import { Send } from 'lucide-react';

const ChatSystem = () => {
  const { user } = useContext(AuthContext);
  const [chats, setChats] = useState([]);
  const [selectedChat, setSelectedChat] = useState(null);
  const [messages, setMessages] = useState([]);
  const [newMessage, setNewMessage] = useState('');

  // 1. Listen for Chats where the owner is involved
  useEffect(() => {
    if (!user) return;

    const q = query(
      collection(db, 'chats'),
      where('users', 'array-contains', user.id)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const chatList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setChats(chatList);
    });

    return () => unsubscribe();
  }, [user]);

  // 2. Listen for Messages in selected chat
  useEffect(() => {
    if (!selectedChat) return;

    const q = query(
      collection(db, 'chats', selectedChat.id, 'messages'),
      orderBy('timestamp', 'asc')
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const msgList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setMessages(msgList);
    });

    return () => unsubscribe();
  }, [selectedChat]);

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim() || !selectedChat) return;

    const messageText = newMessage.trim();
    setNewMessage('');

    await addDoc(collection(db, 'chats', selectedChat.id, 'messages'), {
      senderId: user.id,
      senderName: user.name || 'Owner',
      text: messageText,
      timestamp: serverTimestamp(),
    });

    // Update last message in chat doc
    await setDoc(doc(db, 'chats', selectedChat.id), {
      lastMessage: messageText,
      lastTimestamp: serverTimestamp(),
    }, { merge: true });
  };

  return (
    <Row className="chat-system" style={{ height: '70vh' }}>
      <Col md={4} className="border-end overflow-auto h-100">
        <h5 className="mb-3">Conversations</h5>
        <ListGroup>
          {chats.map(chat => (
            <ListGroup.Item
              key={chat.id}
              action
              active={selectedChat?.id === chat.id}
              onClick={() => setSelectedChat(chat)}
              className="d-flex justify-content-between align-items-start"
            >
              <div className="ms-2 me-auto">
                <div className="fw-bold">{chat.userName || 'Customer'}</div>
                <small className="text-truncate d-inline-block" style={{ maxWidth: '150px' }}>
                  {chat.lastMessage}
                </small>
              </div>
            </ListGroup.Item>
          ))}
        </ListGroup>
        {chats.length === 0 && <p className="text-muted text-center mt-4">No active chats.</p>}
      </Col>

      <Col md={8} className="d-flex flex-column h-100">
        {selectedChat ? (
          <>
            <div className="chat-header p-2 border-bottom">
              <h6>Chat with {selectedChat.userName}</h6>
            </div>
            <div className="chat-messages flex-grow-1 overflow-auto p-3 bg-light">
              {messages.map((msg) => {
                const isMe = msg.senderId === user.id;
                return (
                  <div key={msg.id} className={`d-flex mb-3 ${isMe ? 'justify-content-end' : 'justify-content-start'}`}>
                    <div 
                      className={`p-2 rounded ${isMe ? 'bg-primary text-white' : 'bg-white border'}`}
                      style={{ maxWidth: '75%' }}
                    >
                      <div>{msg.text}</div>
                    </div>
                  </div>
                );
              })}
            </div>
            <Form onSubmit={handleSendMessage} className="p-3 border-top">
              <Row>
                <Col>
                  <Form.Control
                    placeholder="Type a message..."
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                  />
                </Col>
                <Col xs="auto">
                  <Button type="submit" variant="primary">
                    <Send size={18} />
                  </Button>
                </Col>
              </Row>
            </Form>
          </>
        ) : (
          <div className="h-100 d-flex align-items-center justify-content-center text-muted">
            Select a conversation to start chatting
          </div>
        )}
      </Col>
    </Row>
  );
};

export default ChatSystem;
