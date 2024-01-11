#ifndef SIMPER_SAFE_MAP_H_
#define SIMPER_SAFE_MAP_H_
///< 不是最优的方案，因为锁住了整个数据结构
#include <map>
#include <mutex>
template<typename Key, typename Val>
class SimperSafeMap
{
public:
	typedef typename std::map<Key, Val>::iterator this_iterator;
	typedef typename std::map<Key, Val>::const_iterator this_const_iterator;
	/// @brief 
	/// @param key key
	/// @return 值
	Val& operator [](const Key& key) 
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_[key];
	}
	void insert(const Key& key ,Val &val)
	{
		std::lock_guard<std::mutex> lk(mtx_);
		dataMap_[key]=val;
		return ;
	}
	this_iterator erase(this_iterator iter)
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.erase(iter);
	}
 	this_iterator erase(const Key& key)
	{
		std::lock_guard<std::mutex> lk(mtx_);
		auto iter=dataMap_.find(key);
		if(iter!=dataMap_.end())
		{
			iter=dataMap_.erase(iter);
		}
		return iter;
	}
	this_iterator find( const Key& key )
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.find(key);
	}
	this_const_iterator find( const Key& key ) const
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.find(key);
	}
	int size()
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.size();
	}
	this_iterator begin()
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.begin();
	}
	this_const_iterator begin() const
	{
		return dataMap_.begin();
	}
	this_iterator end()
	{
		return dataMap_.end();
	}
	
	this_const_iterator end() const
	{
		return dataMap_.end();
	}
	void clear()
	{
		std::lock_guard<std::mutex> lk(mtx_);
		return dataMap_.clear();
	}
	
private:
	std::map<Key, Val> dataMap_;
	#ifdef ANDROID	
	mutable
	#endif
	std::mutex mtx_;
};
 
#endif //SAFE_MAP_H_