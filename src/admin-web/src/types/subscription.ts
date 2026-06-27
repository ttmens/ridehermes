export interface Subscription {
  id: number;
  driver_id: number;
  driver_name?: string;
  driver_phone?: string;
  plan: number;
  plan_name?: string;
  status: number;
  price: number;
  payment_method?: string;
  start_date: string;
  end_date: string;
  auto_renew: boolean;
  created_at: string;
  updated_at?: string;
}

export interface SubscriptionStats {
  total_subscriptions: number;
  active_subscriptions: number;
  trial_subscriptions: number;
  expired_subscriptions: number;
  cancelled_subscriptions: number;
  monthly_revenue: number;
  total_revenue: number;
  renewal_rate: number;
  plan_distribution: Record<string, number>;
}

export interface SubscriptionTrend {
  date: string;
  new_subscriptions: number;
  cancellations: number;
  revenue: number;
}

export interface PlanDistribution {
  plan: string;
  plan_type?: string;
  count: number;
  percentage: number;
}
