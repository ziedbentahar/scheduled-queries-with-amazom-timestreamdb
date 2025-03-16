export type TrendingProducts = {
    eventType: string;
    time: string;
    products: {
        productId: string;
        count: number;
        increaseLastHour: number;
    }[];
};
