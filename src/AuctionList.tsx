import './AuctionList.css';
import { useEffect, useState } from "react";
import { Item } from "./declarations/backend/backend.did";
import { backend } from "./declarations/backend";
import { Link, useNavigate } from "react-router-dom";

function AuctionList() {
    const [items, setItems] = useState<Item[] | undefined>();
    const navigate = useNavigate();

    const getImageSource = (item: Item) => {
        const data = item.image;
        if (data != null) {
            const array = Uint8Array.from(data);
            const blob = new Blob([array.buffer], { type: 'image/png' });
            return URL.createObjectURL(blob);
        } else {
            return "";    
        }
    }

    const navigationLink = (auctionId: number) => "/viewAuction/" + auctionId;

    const list = items?.map(item => {
        const id = items?.indexOf(item);
        return (
            <li key={id} className="gallery-item" onClick={(_) => navigate(navigationLink(id))}>
                <div className="auction-title">{item?.title}</div>
                <div className="auction-description">{item?.description}</div>
                <img src={getImageSource(item)}/>
                <div className="gallery-item-link">
                    <Link to={navigationLink(id)}>Auction details</Link>
                </div>
            </li>
        );
    });

    const fetchAuction = async() => {
        let result = await backend.getItems();
        setItems(result);
    }

    useEffect(() => {
        fetchAuction();
    }, []);

    return (
        <>
        { items == null &&
            <p>loading</p>
        }
        { items?.length == 0 &&
            <p>...no auctions created so far...</p>
        }
        { items != null && items.length > 0 &&
            <ul className="gallery">
                {list}
            </ul>
        }
        </>
    );
}

export default AuctionList;
