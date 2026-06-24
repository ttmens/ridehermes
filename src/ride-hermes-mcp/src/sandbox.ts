// Sandbox mode - returns mock data without hitting real backend

export const mockPOIs = [
  { name: "北京西站", address: "丰台区莲花池东路", location: "116.321,39.896", type: "交通枢纽" },
  { name: "国贸商圈", address: "朝阳区建国门外大街", location: "116.461,39.909", type: "商业区" },
  { name: "望京SOHO", address: "朝阳区望京街10号", location: "116.481,39.989", type: "写字楼" },
  { name: "三里屯太古里", address: "朝阳区三里屯路", location: "116.454,39.935", type: "购物中心" },
  { name: "中关村", address: "海淀区中关村大街", location: "116.316,39.982", type: "科技园区" },
];

export const mockRoute = {
  origin: "116.321,39.896",
  destination: "116.481,39.989",
  distance: "15200",
  duration: "2400",
  steps: [
    { instruction: "向东北行驶", road: "莲花池东路", distance: "500", duration: "60" },
    { instruction: "右转进入二环", road: "二环", distance: "8000", duration: "900" },
    { instruction: "左转进入京承高速", road: "京承高速", distance: "6700", duration: "1440" },
  ],
};

let orderCounter = 1000;
const activeOrders: Map<string, any> = new Map();

export function createMockOrder(pickup: string, dropoff: string, carType: number): any {
  const orderId = `MOCK-${++orderCounter}`;
  const order = {
    id: orderId,
    order_no: orderId,
    status: 1,
    status_text: "司机已接单",
    est_price: carType === 1 ? 45 : carType === 2 ? 78 : 120,
    est_distance: 12500,
    est_duration: 1800,
    pickup_addr: pickup,
    dropoff_addr: dropoff,
    driver: {
      nickname: "张师傅",
      rating: 4.9,
      vehicle: {
        plate_number: "京A·12345",
        brand: carType === 1 ? "大众" : carType === 2 ? "奥迪" : "奔驰",
        model: carType === 1 ? "帕萨特" : carType === 2 ? "A6L" : "E级",
        color: "白色",
      },
    },
  };
  activeOrders.set(orderId, order);
  return order;
}

export function getMockOrder(orderId: string): any | null {
  return activeOrders.get(orderId) || null;
}

export function cancelMockOrder(orderId: string): boolean {
  const order = activeOrders.get(orderId);
  if (order) {
    order.status = 5;
    order.status_text = "已取消";
    return true;
  }
  return false;
}

export function getMockEstimate(): any[] {
  return [
    { car_type: 1, car_type_name: "快车", est_price: 45, est_distance: 12500, est_duration: 1800 },
    { car_type: 2, car_type_name: "专车", est_price: 78, est_distance: 12500, est_duration: 1800 },
    { car_type: 3, car_type_name: "豪华车", est_price: 120, est_distance: 12500, est_duration: 1800 },
  ];
}
