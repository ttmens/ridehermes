import axios, { type AxiosResponse, type InternalAxiosRequestConfig } from 'axios';
import { message } from 'antd';
import { getToken, clearToken } from '@/utils/token';

const api = axios.create({
  baseURL: '/api/v1',
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getToken();
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

api.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message: msg, data } = response.data;
    if (code !== 0) {
      message.error(msg || '请求失败');
      return Promise.reject(new Error(msg));
    }
    return { ...response, data };
  },
  (error) => {
    const { response } = error;
    if (!response) {
      message.error('网络异常，请检查网络连接');
      return Promise.reject(error);
    }

    const { status, data } = response;

    if (status === 401) {
      clearToken();
      window.location.href = '/admin/login';
      return Promise.reject(error);
    }

    if (status === 403) {
      message.error('无权限访问');
    } else if (status === 404) {
      message.error('资源不存在');
    } else if (status >= 500) {
      message.error('服务器异常');
    } else {
      message.error(data?.message || '请求失败');
    }

    return Promise.reject(error);
  },
);

export default api;
